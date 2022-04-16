import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Predictsea, PredictNFT } from "../typechain"
import state from "./variables"

describe("Submit closing vote", async function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000"
  let contractOwner: SignerWithAddress
  let contract: Predictsea
  let minerNFT: PredictNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress
  let miner1: SignerWithAddress
  let miner2: SignerWithAddress
  let miner3: SignerWithAddress
  let miner4: SignerWithAddress
  let miner5: SignerWithAddress
  let miner6: SignerWithAddress

  beforeEach(async function () {
    const Predictsea = await ethers.getContractFactory("Predictsea")
    ;[
      contractOwner,
      user1,
      user2,
      miner1,
      miner2,
      miner3,
      miner4,
      miner5,
      miner6,
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

    const latestBlock = await ethers.provider.getBlock("latest")
    const _startTime = latestBlock.timestamp + 43200
    const _endTime = _startTime + 86400
    await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await minerNFT
      .connect(contractOwner)
      .setSellingPrice(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).increaseMintLimit(6)
    await minerNFT.connect(miner1).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner2).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner3).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
    await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")
    await minerNFT.connect(miner3).mintToken("http://ipfs.io/json3")

    await minerNFT.connect(miner1).approve(contract.address, 1)
    await minerNFT.connect(miner2).approve(contract.address, 2)
    await minerNFT.connect(miner3).approve(contract.address, 3)

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

    await contract.connect(miner1).submitOpeningVote(1, 1, 1)

    await contract.connect(miner2).submitOpeningVote(1, 2, 1)

    await contract.connect(miner3).submitOpeningVote(1, 3, 1)
  })

  it("allows miner submit closing win vote", async function () {
    expect(await minerNFT.ownerOf(1)).to.equal(contract.address)
    expect(await contract.TokenOwner(1)).to.equal(miner1.address)
    expect((await contract.PredictionStats(1)).wonVoteCount).equal(0)
    expect((await contract.PredictionStats(1)).lostVoteCount).equal(0)
    expect((await contract.Validations(1, 1)).closing).to.equal(0)
    await ethers.provider.send("evm_increaseTime", [122500])
    await contract.connect(miner1).submitClosingVote(1, 1, 1)
    expect((await contract.PredictionStats(1)).wonVoteCount).equal(1)
    expect((await contract.PredictionStats(1)).lostVoteCount).equal(0)
    expect((await contract.Validations(1, 1)).closing).to.equal(1)
    expect(await minerNFT.ownerOf(1)).to.equal(miner1.address)
    expect(await contract.TokenOwner(1)).to.equal(zeroAddress)
  })

  it("allows miner submit closing loss vote", async function () {
    expect(await minerNFT.ownerOf(1)).to.equal(contract.address)
    expect(await contract.TokenOwner(1)).to.equal(miner1.address)
    expect((await contract.PredictionStats(1)).wonVoteCount).equal(0)
    expect((await contract.PredictionStats(1)).lostVoteCount).equal(0)
    expect((await contract.Validations(1, 1)).closing).to.equal(0)
    await ethers.provider.send("evm_increaseTime", [122500])
    await contract.connect(miner1).submitClosingVote(1, 1, 2)
    expect((await contract.PredictionStats(1)).wonVoteCount).equal(0)
    expect((await contract.PredictionStats(1)).lostVoteCount).equal(1)
    expect((await contract.Validations(1, 1)).closing).to.equal(2)
    expect(await minerNFT.ownerOf(1)).to.equal(miner1.address)
    expect(await contract.TokenOwner(1)).to.equal(zeroAddress)
  })

  it("reverts if prediction is not active", async function () {
    const latestBlock = await ethers.provider.getBlock("latest")
    const _startTime = latestBlock.timestamp + 43200
    const _endTime = _startTime + 86400
    await contract
      .connect(user2)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )
    await expect(
      contract.connect(miner1).submitClosingVote(2, 1, 1),
    ).to.be.revertedWith("Prediction currently inactive")
  })

  it("reverts if miner not nft owner", async function () {
    await ethers.provider.send("evm_increaseTime", [122500])
    await expect(
      contract.connect(miner1).submitClosingVote(1, 2, 1),
    ).to.be.revertedWith("Not NFT Owner")
  })

  it("reverts if closing vote option is invalid", async function () {
    await ethers.provider.send("evm_increaseTime", [122500])
    await expect(
      contract.connect(miner1).submitClosingVote(1, 1, 3),
    ).to.be.revertedWith("Invalid validation option")
  })

  it("reverts if current time is less that 2hrs after prediction ends", async function () {
    await ethers.provider.send("evm_increaseTime", [122000])
    await expect(
      contract.connect(miner1).submitClosingVote(1, 1, 1),
    ).to.be.revertedWith("Can't cast closing vote now")
  })

  it("reverts if current time > 6hrs after prediction events end", async function () {
    await ethers.provider.send("evm_increaseTime", [144000])
    await expect(
      contract.connect(miner1).submitClosingVote(1, 1, 1),
    ).to.be.revertedWith("Vote window period expired")
  })

  it("reverts if prediction is not assigned to miner", async function () {
    const latestBlock = await ethers.provider.getBlock("latest")
    const _startTime = latestBlock.timestamp + 43200
    const _endTime = _startTime + 86400
    await contract
      .connect(user2)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await minerNFT.connect(miner4).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner5).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner6).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner4).mintToken("http://ipfs.io/json4")
    await minerNFT.connect(miner5).mintToken("http://ipfs.io/json5")
    await minerNFT.connect(miner6).mintToken("http://ipfs.io/json6")

    await minerNFT.connect(miner4).approve(contract.address, 4)
    await minerNFT.connect(miner5).approve(contract.address, 5)
    await minerNFT.connect(miner6).approve(contract.address, 6)

    await ethers.provider.send("evm_increaseTime", [14400])

    await contract.connect(miner4).requestValidation(
      4, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner5).requestValidation(
      5, //tokenId
      "miner2_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner6).requestValidation(
      6, //tokenId
      "miner3_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await ethers.provider.send("evm_increaseTime", [108100])
    await expect(
      contract.connect(miner6).submitClosingVote(1, 6, 1),
    ).to.be.revertedWith("Not assigned to miner")
  })

  it("should revert if miner already cast closing vote", async function () {
    const latestBlock = await ethers.provider.getBlock("latest")
    await ethers.provider.send("evm_increaseTime", [122500])
    const _startTime = latestBlock.timestamp + 43200 + 122500
    const _endTime = _startTime + 86400

    await contract
      .connect(user2)
      .createPrediction(
        "hellothere123",
        "hithere123",
        _startTime,
        _endTime,
        2,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await minerNFT.connect(miner1).approve(contract.address, 1)
    await ethers.provider.send("evm_increaseTime", [14400])
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await expect(
      contract.connect(miner1).submitClosingVote(1, 1, 2),
    ).to.be.revertedWith("Closing vote already cast")
  })
})
