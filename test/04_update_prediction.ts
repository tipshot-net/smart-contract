import { expect } from "chai";
import { ethers } from "hardhat";
const { BigNumber } = require("ethers");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea } from "../typechain";
import state from "./variables";

describe("updatePrediction function", async function () {

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

  it("allows seller to update prediction data", async function () {
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
      
      await contract.connect(user1).updatePrediction(
        1,
        "newipfshash123",
        "newkey123",
        _startTime + 3600,
        _endTime + 3600,
        3,
        ethers.utils.parseEther("20.0"),
        );

      const current = await contract.Predictions(1);
      expect(current.seller).to.equal(user1.address);
      expect(current.ipfsHash).to.equal("newipfshash123");
      expect(current.key).to.equal("newkey123");
      expect(BigNumber.from(current.createdAt)).to.be.closeTo(BigNumber.from(latestBlock.timestamp), 5);
      expect(current.startTime).to.equal(_startTime + 3600);
      expect(current.endTime).to.equal(_endTime + 3600);
      expect(current.odd).to.equal(3);
      expect(current.price).to.equal(ethers.utils.parseEther("20.0"));
      expect(await contract.miningPool(0)).to.equal(1)
      expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1);
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1);
      expect(await contract.connect(user1).getOwnedPredictionsLength(user1.address)).to.equal(1);

  })

  it("reverts if prediction data updated by non seller", async function () {
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
    
    await expect(contract.connect(user2).updatePrediction(
      1,
      "newipfshash123",
      "newkey123",
      _startTime + 3600,
      _endTime + 3600,
      3,
      ethers.utils.parseEther("20.0"),
      )).to.be.revertedWith("Only prediction seller");
  })

    it("reverts if prediction to be updated has been assigned to a miner",async function () {
      //todo
    })



})