import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Predictsea, PredictNFT } from "../typechain"
import state from "./variables"

describe("Refund buyer", async function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000"
  let contractOwner: SignerWithAddress
  let contract: Predictsea
  let minerNFT: PredictNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress
  let buyer1: SignerWithAddress
  let buyer2: SignerWithAddress
  let buyer3: SignerWithAddress
  let buyer4: SignerWithAddress
  let buyer5: SignerWithAddress
  let miner1: SignerWithAddress
  let miner2: SignerWithAddress
  let miner3: SignerWithAddress
  let miner4: SignerWithAddress
  let miner5: SignerWithAddress
  

  beforeEach(async function () {
    const Predictsea = await ethers.getContractFactory("Predictsea")
    ;[
      contractOwner,
      user1,
      user2,
      buyer1,
      buyer2,
      buyer3,
      buyer4,
      buyer5,
      miner1,
      miner2,
      miner3,
      miner4,
      miner5,
      

    ] = await ethers.getSigners()
    contract = await Predictsea.deploy()
    await contract.deployed()

    const PredictNFT = await ethers.getContractFactory("PredictNFT")
    minerNFT = await PredictNFT.deploy()
    await minerNFT.deployed()
    await contract.connect(contractOwner).setNftAddress(minerNFT.address)

    await contract
      .connect(contractOwner)
      .setVariables(
        state.miningFee,
        state.minerStakingFee,
        state.minerPercentage,
      )
    
    await contract.connect(contractOwner).setFreeTipsQuota(100)
    

    const latestBlock = await ethers.provider.getBlock("latest")
    const _startTime = latestBlock.timestamp + 43200
    let _endTime = _startTime + 86400
    await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

      await contract
      .connect(user2)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await minerNFT
      .connect(contractOwner)
      .setSellingPrice(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).increaseMintLimit(8)
    await minerNFT.connect(miner1).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner2).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner3).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner4).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner5).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    

    await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
    await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")
    await minerNFT.connect(miner3).mintToken("http://ipfs.io/json3")
    await minerNFT.connect(miner4).mintToken("http://ipfs.io/json4")
    await minerNFT.connect(miner5).mintToken("http://ipfs.io/json5")
    
    await minerNFT.connect(miner1).approve(contract.address, 1)
    await minerNFT.connect(miner2).approve(contract.address, 2)
    await minerNFT.connect(miner3).approve(contract.address, 3)
    await minerNFT.connect(miner4).approve(contract.address, 4)
    await minerNFT.connect(miner5).approve(contract.address, 5)
    

    await ethers.provider.send("evm_increaseTime", [14400])
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner2).requestValidation(
      2, //tokenId
      "miner2_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner3).requestValidation(
      3, //tokenId
      "miner3_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner4).requestValidation(
      4, //tokenId
      "miner4_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner5).requestValidation(
      5, //tokenId
      "miner5_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    
    await contract.connect(miner1).submitOpeningVote(1, 1, 1)

    await contract.connect(miner2).submitOpeningVote(1, 2, 1)

    await contract.connect(miner3).submitOpeningVote(1, 3, 1)

    await contract.connect(miner4).submitOpeningVote(1, 4, 1)

    await contract.connect(miner5).submitOpeningVote(1, 5, 1)

   


    await contract.connect(buyer1).purchasePrediction(1, "buyerkey1", {
      value: ethers.utils.parseEther("0.0")
    })
    
    

    await ethers.provider.send("evm_increaseTime", [136000]);
  })

  it("reverts if prediction not yet concluded", async function () {
   
    await expect(contract.connect(buyer1).refundBuyer(1)).to.be.revertedWith("Prediction not concluded");

  })

  it("reverts if non buyer tries to get refund", async function () {
    await contract.connect(miner1).submitClosingVote(1, 1, 2)

    await contract.connect(miner2).submitClosingVote(1, 2, 2)

    await contract.connect(miner3).submitClosingVote(1, 3, 2)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await contract.connect(miner5).submitClosingVote(1, 5, 2)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1);

    await expect(contract.connect(user2).refundBuyer(1)).to.be.revertedWith("No purchase history found")


  })

  it("reverts if prediction won", async function () {

    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await contract.connect(miner2).submitClosingVote(1, 2, 1)

    await contract.connect(miner3).submitClosingVote(1, 3, 1)

    await contract.connect(miner4).submitClosingVote(1, 4, 1)

    await contract.connect(miner5).submitClosingVote(1, 5, 1)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1);

    await expect(contract.connect(buyer1).refundBuyer(1)).to.be.revertedWith("Prediction won")
    
  })

  it("allows buyer refund if prediction lost", async function () {
    
    await contract.connect(miner1).submitClosingVote(1, 1, 2)

    await contract.connect(miner2).submitClosingVote(1, 2, 2)

    await contract.connect(miner3).submitClosingVote(1, 3, 2)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await contract.connect(miner5).submitClosingVote(1, 5, 2)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1);

    expect((await contract.Purchases(buyer1.address, 1)).refunded).to.be.false;

    await contract.connect(buyer1).refundBuyer(1);

    expect(await contract.Balances(buyer1.address)).to.equal((await contract.Predictions(1)).price);

    expect((await contract.Purchases(buyer1.address, 1)).refunded).to.be.true;

    await expect(contract.connect(buyer1).refundBuyer(1)).to.be.revertedWith("Already refunded")

    
  })

  




});