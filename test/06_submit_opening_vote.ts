import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Predictsea, PredictNFT } from "../typechain";
import state from "./variables";


describe("submitOpeningVote function", async function () {

  let contractOwner: SignerWithAddress;
  let contract: Predictsea;
  let minerNFT: PredictNFT
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let miner1: SignerWithAddress;
  let miner2: SignerWithAddress; 
  let miner3: SignerWithAddress

  beforeEach(async function () { 
    const Predictsea = await ethers.getContractFactory("Predictsea");
    [contractOwner, user1, user2, miner1, miner2, miner3] = await ethers.getSigners();
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
  });

    it("allows miner to submit opening upvote", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      expect((await contract.PredictionStats(1)).upvoteCount).to.equal(0)
      expect((await contract.PredictionStats(1)).downvoteCount).to.equal(0)
      expect((await contract.Validations(1,1)).opening).to.equal(0)

      await contract.connect(miner1).submitOpeningVote(1, 1, 1);

      expect((await contract.PredictionStats(1)).upvoteCount).to.equal(1)
      expect((await contract.PredictionStats(1)).downvoteCount).to.equal(0)
      expect((await contract.Validations(1,1)).opening).to.equal(1)
      expect(await contract.Balances(miner1.address)).to.equal(state.miningFee.div(state.MAX_VALIDATORS))

    })

    it("allows miner to submit opening downvote", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      expect((await contract.PredictionStats(1)).upvoteCount).to.equal(0)
      expect((await contract.PredictionStats(1)).downvoteCount).to.equal(0)
      expect((await contract.Validations(1,1)).opening).to.equal(0)
      await contract.connect(miner1).submitOpeningVote(1, 1, 2);

      expect((await contract.PredictionStats(1)).upvoteCount).to.equal(0)
      expect((await contract.PredictionStats(1)).downvoteCount).to.equal(1)
      expect((await contract.Validations(1,1)).opening).to.equal(2)
      expect(await contract.Balances(miner1.address)).to.equal(state.miningFee.div(state.MAX_VALIDATORS))

    })

    it("reverts if prediction event already started", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      await ethers.provider.send("evm_increaseTime", [28900]);

      await expect(contract.connect(miner1).submitOpeningVote(1, 1, 1)).to.be.revertedWith("Event already started")
    })


    it("reverts if miner is not nft owner", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      await expect(contract.connect(miner1).submitOpeningVote(1, 2, 1)).to.be.revertedWith("Not NFT Owner")
    })

    it("reverts if invalid vote option is passed", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      await expect(contract.connect(miner1).submitOpeningVote(1, 1, 3)).to.be.revertedWith("Invalid validation option")
    })

    it("reverts if prediction not assigned to miner", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const _startTime = latestBlock.timestamp + 43200;
      const _endTime = _startTime + 86400;
      await contract.connect(user2).createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee
        })
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });


      await expect(contract.connect(miner1).submitOpeningVote(2, 1, 1)).to.be.revertedWith("Not assigned to miner")
    })

    it("reverts if miner already casted vote", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });


      await contract.connect(miner1).submitOpeningVote(1, 1, 1);

      await expect(contract.connect(miner1).submitOpeningVote(1, 1, 2)).to.be.revertedWith("Opening vote already cast")
    })

    it("goes active after receiving 60% upvote", async function () {
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

      expect((await contract.PredictionStats(1)).state).to.equal(0)

      expect(await contract.getActivePoolLength()).to.equal(0)

      await contract.connect(miner3).submitOpeningVote(1, 3, 1);

      expect((await contract.PredictionStats(1)).upvoteCount).to.equal(3)
      expect((await contract.PredictionStats(1)).state).to.equal(3)
      expect(await contract.getActivePoolLength()).to.equal(1)
      expect(await contract.activePool(0)).to.equal(1)

    })

    it("is rejected after receiving 60% downvote", async function () {
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

      await contract.connect(miner1).submitOpeningVote(1, 1, 2);

      await contract.connect(miner2).submitOpeningVote(1, 2, 2);

      expect((await contract.PredictionStats(1)).state).to.equal(0)


      await contract.connect(miner3).submitOpeningVote(1, 3, 2);

      expect((await contract.PredictionStats(1)).downvoteCount).to.equal(3)
      expect((await contract.PredictionStats(1)).state).to.equal(2)
      expect(await contract.getActivePoolLength()).to.equal(0)
    })

   





})