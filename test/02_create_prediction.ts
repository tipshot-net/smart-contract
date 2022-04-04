import { expect } from "chai";
import { ethers } from "hardhat";
const { BigNumber } = require("ethers");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea } from "../typechain";
import state from "./variables";


describe("createPrediction function", async function () {

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

  describe("seller creates prediction", async function () {
    
    it("sets all prediction data", async function () {
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
    const current = await contract.Predictions(1);
    expect(current.seller).to.equal(user1.address);
    expect(current.ipfsHash).to.equal("hellothere123");
    expect(current.key).to.equal("hithere123");
    expect(BigNumber.from(current.createdAt)).to.be.closeTo(BigNumber.from(latestBlock.timestamp), 5);
    expect(current.startTime).to.equal(_startTime);
    expect(current.endTime).to.equal(_endTime);
    expect(current.odd).to.equal(2);
    expect(current.price).to.equal(ethers.utils.parseEther("10.0"));
    expect(await contract.miningPool(0)).to.equal(1)
    expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1);
     
    })

    //time considerations

    it("should revert if start time is less than 8 hours from now", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 21600;
      const _endTime = _startTime + 86400;
      await expect(contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee)
        })).to.be.revertedWith("Doesn't meet min requirements");

      
    })

    it("should revert if end time is less than start time", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = latestBlock.timestamp + 36000;
      await expect(contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee)
        })).to.be.revertedWith("End time less than start time");
    })

    it("should revert if start time greater than 24 hours from now", async function () {

      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 90000;
      const _endTime = _startTime + 86400;

      await expect(contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee)
        })).to.be.revertedWith("Doesn't meet min requirements")
      
    })


    it("should revert if (endtime - starttime) > 48 hours", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 180000;

      await expect(contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee)
        })).to.be.revertedWith("Doesn't meet min requirements")
    })

    it("reverts if sent eth is less than (miningFee + sellerStakingFee)", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 180000;

      await expect(contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee).sub(ethers.utils.parseEther("2.0"))
        })).to.be.revertedWith("Insufficient balance")
    })

    it("deducts from wallet balance if sent eth is not enough", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;
      let tx = {
        to: contract.address,
        value: ethers.utils.parseEther("5.0") 
    };

      await user1.sendTransaction(tx);
      expect(await contract.Balances(user1.address)).to.be.equal(ethers.utils.parseEther("5.0"))
      await contract.connect(user1).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee.add(state.sellerStakingFee).sub(ethers.utils.parseEther("2.0"))
        })


      const current = await contract.Predictions(1);
      expect(current.seller).to.equal(user1.address);
      expect(current.ipfsHash).to.equal("hellothere123");
      expect(current.key).to.equal("hithere123");
      expect(BigNumber.from(current.createdAt)).to.be.closeTo(BigNumber.from(latestBlock.timestamp), 5);
      expect(current.startTime).to.equal(_startTime);
      expect(current.endTime).to.equal(_endTime);
      expect(current.odd).to.equal(2);
      expect(current.price).to.equal(ethers.utils.parseEther("10.0"));
      expect(await contract.miningPool(0)).to.equal(1)
      expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1);


    expect(await contract.Balances(user1.address)).to.be.equal(ethers.utils.parseEther("3.0"))

    })

    it("creates multiple predictions in mining pool", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;
      for (let index = 0; index < 10; index++) {
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
        
      }

      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(10);
      expect(await contract.miningPool(2)).to.equal(3)
      expect(await contract.miningPool(4)).to.equal(5)
      expect(await contract.miningPool(8)).to.equal(9)
        
    })

  })

});