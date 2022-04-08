import { expect } from "chai";
import { ethers } from "hardhat";
const { BigNumber } = require("ethers");
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

  beforeEach(async function () { 
    const Predictsea = await ethers.getContractFactory("Predictsea");
    [contractOwner, user1, user2, miner1, miner2] = await ethers.getSigners();
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
        await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
        await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")

        await minerNFT.connect(miner1).approve(contract.address, 1);
        await minerNFT.connect(miner2).approve(contract.address, 2);
  });

    it("allows miner to submit opening vote", async function () {
      await ethers.provider.send("evm_increaseTime", [14400]);
      await contract.connect(miner1).requestValidation(1, //tokenId
        "miner1_key", //key
      {
        value: state.minerStakingFee
      });

      await contract.connect(miner1).submitOpeningVote(1, 1, 1);

    })



})
