import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea, PredictNFT } from "../typechain";
import state from "./variables";

describe("requestValidation function", async function () {

  let contractOwner: SignerWithAddress;
  let contract: Predictsea;
  let minerNFT: PredictNFT
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let miner1: SignerWithAddress;
  let miner2: SignerWithAddress; 

  beforeEach(async function () { 
    const Predictsea = await ethers.getContractFactory("Predictsea");
    [contractOwner, user1, user2, miner1, miner2] = await ethers.getSigners();
    contract = await Predictsea.deploy();
    await contract.deployed();

    const predictNFT = await ethers.getContractFactory("PredictNFT");
    minerNFT = await predictNFT.deploy();
    await minerNFT.deployed();
    await contract.connect(contractOwner).setNftAddress(minerNFT.address);

    await contract.connect(contractOwner).setVariables(
      state.miningFee,
      state.sellerStakingFee,
      state.minerStakingFee,
      state.minerPercentage
      );
    
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;

      await contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee)
        })

        await contract.connect(user2).createPrediction(
          "newipfshash123",
          "newkey123",
          _startTime + 3600,
          _endTime + 3600,
          3,
          ethers.utils.parseEther("20.0"),
          {
            value: state.miningFee.add(state.sellerStakingFee)
          });

          await minerNFT.connect(contractOwner).setSellingPrice(ethers.utils.parseEther("2.0"))
          await minerNFT.connect(contractOwner).increaseMintLimit(2);
          await minerNFT.connect(miner1).whitelist({
            value: ethers.utils.parseEther("2.0")
          })
          await minerNFT.connect(miner2).whitelist({
            value: ethers.utils.parseEther("2.0")
          })
          await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
          await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")

          await minerNFT.connect(miner1).approve(contract.address, 1);
          await minerNFT.connect(miner2).approve(contract.address, 2);
  });

  it("assignes predicition to miner", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    expect((await contract.Validations(1, 1)).assigned).to.be.false;
    expect((await contract.Predictions(1)).validatorCount).to.equal(0)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(0)
    await contract.connect(miner1).requestValidation(1, //tokenId
       "miner1_key", //key
    {
      value: state.minerStakingFee
    });

    
    expect(await minerNFT.connect(contractOwner).ownerOf(1)).to.equal(contract.address);
    expect((await contract.Validations(1, 1)).assigned).to.be.true;
    expect((await contract.Predictions(1)).validatorCount).to.equal(1)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).id).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).tokenId).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).key).to.equal("miner1_key")

  })

})