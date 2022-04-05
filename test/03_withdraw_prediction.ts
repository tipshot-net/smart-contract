import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea } from "../typechain";
import state from "./variables";

describe("withdrawPrediction function", async function () {

  let contractOwner: SignerWithAddress;
  let contract: Predictsea;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () { 
    const Predictsea = await ethers.getContractFactory("Predictsea");
    [contractOwner, user1, user2] = await ethers.getSigners();
    contract = await Predictsea.deploy();
    await contract.deployed();

    const PredictNFT = await ethers.getContractFactory("PredictNFT");
    const NFT = await PredictNFT.deploy();
    await NFT.deployed();
    await contract.connect(contractOwner).setNftAddress(NFT.address);

    await contract.connect(contractOwner).setVariables(
      state.miningFee,
      state.sellerStakingFee,
      state.minerStakingFee,
      state.minerPercentage
      );
  });

  describe("seller withdraw prediction before it was mined", async function () {
    it("withdraws prediction from mining pool", async function () {
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
        expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1);
      expect(await contract.miningPool(0)).to.equal(1);
      expect(await contract.Balances(user1.address)).to.equal(0);
      await contract.connect(user1).withdrawPrediction(1);
      expect(await contract.miningPool(0)).to.equal(0);
      expect((await contract.Predictions(1)).state).to.equal(1) //withdrawn
      expect(await contract.Balances(user1.address)).to.equal(state.miningFee.add(state.sellerStakingFee))
      await expect(contract.connect(user1).withdrawPrediction(1)).to.be.revertedWith("Prediction already withdrawn!")
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1);
    })
  })

  it("should revert if non seller tries to withdraw prediction", async () => {
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
      await expect(contract.connect(user2).withdrawPrediction(1)).to.be.revertedWith("Only prediction seller")
      expect(await contract.miningPool(0)).to.equal(1);
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1);
  })

  it("reverts if prediction to be withdrawn has already been assigned to a miner", async function () {
    //todo
      


  })

})