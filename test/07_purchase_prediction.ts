import { expect } from "chai";
import { ethers } from "hardhat";
const { BigNumber } = require("ethers");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea, PredictNFT } from "../typechain";
import state from "./variables";


describe("Purchase prediction", async function () {

  let contractOwner: SignerWithAddress;
  let contract: Predictsea;
  let minerNFT: PredictNFT
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let miner1: SignerWithAddress;
  let miner2: SignerWithAddress; 
  let miner3: SignerWithAddress
  let buyer1: SignerWithAddress
  let buyer2: SignerWithAddress

  beforeEach(async function () { 
    const Predictsea = await ethers.getContractFactory("Predictsea");
    [contractOwner, user1, user2, miner1, miner2, miner3, buyer1, buyer2] = await ethers.getSigners();
    contract = await Predictsea.deploy();
    await contract.deployed();

    const PredictNFT = await ethers.getContractFactory("PredictNFT");
    minerNFT = await PredictNFT.deploy();
    await minerNFT.deployed();
    await contract.connect(contractOwner).setNftAddress(minerNFT.address);

    await contract.connect(contractOwner).setVariables(
      state.miningFee,
      state.minerStakingFee,
      state.minerPercentage
      );
      
    await contract.connect(contractOwner).setFreeTipsQuota(100)

      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;
      await contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee
        })

        await minerNFT.connect(contractOwner).setSellingPrice(ethers.utils.parseEther("2.0"))
        await minerNFT.connect(contractOwner).increaseMintLimit(6);
        await minerNFT.connect(miner1).whitelist({
          value: ethers.utils.parseEther("2.0")
        })
        await minerNFT.connect(miner2).whitelist({
          value: ethers.utils.parseEther("2.0")
        })
        await minerNFT.connect(miner3).whitelist({
          value: ethers.utils.parseEther("2.0")
        })
        await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
        await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")
        await minerNFT.connect(miner3).mintToken("http://ipfs.io/json3")

        await minerNFT.connect(miner1).approve(contract.address, 1);
        await minerNFT.connect(miner2).approve(contract.address, 2);
        await minerNFT.connect(miner3).approve(contract.address, 3);

      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      await contract.connect(miner2).requestValidation(2, //tokenId
        "miner2_key", //key
      {
        value: state.minerStakingFee
      });

      await contract.connect(miner3).requestValidation(3, //tokenId
        "miner3_key", //key
      {
        value: state.minerStakingFee
      });

      await contract.connect(miner1).submitOpeningVote(1, 1, 1);

      await contract.connect(miner2).submitOpeningVote(1, 2, 1);

      await contract.connect(miner3).submitOpeningVote(1, 3, 1);
  });


  it("allows user to purchase active prediction", async function () {
    expect((await contract.PredictionStats(1)).buyCount).to.equal(0) 
    expect(await contract.getBoughtPredictionsLength(buyer1.address)).to.equal(0)
    await contract.connect(buyer1).purchasePrediction(1, "mykey", {
      value: ethers.utils.parseEther("10.0")
    })

    expect((await contract.Purchases(buyer1.address, 1)).purchased).to.be.true;
    expect((await contract.Purchases(buyer1.address, 1)).key).to.equal("mykey");
    expect((await contract.PredictionStats(1)).buyCount).to.equal(1);
    expect(await contract.getBoughtPredictionsLength(buyer1.address)).to.equal(1)
    expect(await contract.BoughtPredictions(buyer1.address, 0)).to.equal(1);
    

  })

  

  it("reverts if prediction event already started", async function () {
    await ethers.provider.send("evm_increaseTime", [28900]);
    await expect(contract.connect(buyer1).purchasePrediction(1, "mykey", {
      value: ethers.utils.parseEther("10.0")
    })).to.be.revertedWith("Event already started");
    expect((await contract.Purchases(buyer1.address, 1)).purchased).to.be.false;
  })

  it("reverts if prediction not active", async function () {
    const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;
      await contract.connect(user2).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee
        })
    await expect(contract.connect(buyer1).purchasePrediction(2, "mykey", {
      value: ethers.utils.parseEther("10.0")
    })).to.be.revertedWith("Prediction currently inactive");
    expect((await contract.Purchases(buyer1.address, 2)).purchased).to.be.false;
  })

})