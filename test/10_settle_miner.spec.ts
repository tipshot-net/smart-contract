import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Settle miner", async function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000"
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let minerNFT: MinerNFT
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
  let miner6: SignerWithAddress
  let miner7: SignerWithAddress
  let miner8: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot")
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
      miner6,
      miner7,
      miner8,
    ] = await ethers.getSigners()
    contract = await Tipshot.deploy()
    await contract.deployed()

    const MinerNFT = await ethers.getContractFactory("MinerNFT")
    minerNFT = await MinerNFT.deploy(
      "Tipshot-Miner",
      "TMT",
      "https://ipfs.io/kdkij99u9nsk/",
    )
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
      .setCost(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).whitelistUser(miner1.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner2.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner3.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner4.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner5.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner6.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner7.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner8.address)

    await minerNFT.connect(miner1).mint(miner1.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner2).mint(miner2.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner3).mint(miner3.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner4).mint(miner4.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner5).mint(miner5.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner6).mint(miner6.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner7).mint(miner7.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner8).mint(miner8.address, {
      value: ethers.utils.parseEther("2.0"),
    })

    await minerNFT.connect(miner1).approve(contract.address, 1)
    await minerNFT.connect(miner2).approve(contract.address, 2)
    await minerNFT.connect(miner3).approve(contract.address, 3)
    await minerNFT.connect(miner4).approve(contract.address, 4)
    await minerNFT.connect(miner5).approve(contract.address, 5)
    await minerNFT.connect(miner6).approve(contract.address, 6)
    await minerNFT.connect(miner7).approve(contract.address, 7)
    await minerNFT.connect(miner8).approve(contract.address, 8)

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

    await contract.connect(miner6).requestValidation(
      6, //tokenId
      "miner6_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner7).requestValidation(
      7, //tokenId
      "miner7_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner8).requestValidation(
      8, //tokenId
      "miner8_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner1).submitOpeningVote(1, 1, 1)

    await contract.connect(miner2).submitOpeningVote(1, 2, 1)

    await contract.connect(miner3).submitOpeningVote(1, 3, 1)

    await contract.connect(miner4).submitOpeningVote(1, 4, 1)

    await contract.connect(miner5).submitOpeningVote(1, 5, 1)

    await contract.connect(miner6).submitOpeningVote(2, 6, 2)

    await contract.connect(miner7).submitOpeningVote(2, 7, 2)

    await contract.connect(miner8).submitOpeningVote(2, 8, 2)

    await contract.connect(buyer1).purchasePrediction(1, "buyerkey1", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer2).purchasePrediction(1, "buyerkey2", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer3).purchasePrediction(1, "buyerkey3", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer4).purchasePrediction(1, "buyerkey4", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer5).purchasePrediction(1, "buyerkey5", {
      value: ethers.utils.parseEther("10.0"),
    })
  })

  it("tests first closing miner conclude the transaction and other miners settlement when prediction won", async function () {
    await ethers.provider.send("evm_increaseTime", [136000])

    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await contract.connect(miner2).submitClosingVote(1, 2, 1)

    await contract.connect(miner3).submitClosingVote(1, 3, 1)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await contract.connect(miner5).submitClosingVote(1, 5, 2)

    await expect(contract.connect(miner3).settleMiner(1, 3)).to.be.revertedWith(
      "Not cooled down yet",
    )

    await ethers.provider.send("evm_increaseTime", [18000])

    expect((await contract.Predictions(1)).state).to.equal(3)

    expect((await contract.Predictions(1)).winningOpeningVote).to.equal(0)

    expect((await contract.Predictions(1)).winningClosingVote).to.equal(0)

    expect(await contract.getRecentPrediction(user1.address, 0)).to.equal(0)

    expect(await contract.getActivePoolLength()).to.equal(1)

    expect((await contract.Validations(1, 1)).settled).to.be.false

    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS)

    expect(await contract.Balances(miner1.address)).to.equal(miningFeeShare)

    expect((await contract.User(user1.address)).wonCount).to.equal(0)

    expect((await contract.User(user1.address)).lostCount).to.equal(0)

    expect((await contract.User(user1.address)).totalPredictions).to.equal(0)

    await contract.connect(miner1).settleMiner(1, 1)

    expect((await contract.Predictions(1)).state).to.equal(4)

    expect((await contract.User(user1.address)).wonCount).to.equal(1)

    expect((await contract.User(user1.address)).lostCount).to.equal(0)

    expect((await contract.User(user1.address)).totalPredictions).to.equal(1)

    expect((await contract.Predictions(1)).winningOpeningVote).to.equal(1)

    expect((await contract.Predictions(1)).winningClosingVote).to.equal(1)

    expect(await contract.getRecentPrediction(user1.address, 0)).to.equal(1)

    expect(await contract.getActivePoolLength()).to.equal(0)

    expect((await contract.Validations(1, 1)).settled).to.be.true

    let minerReward = (await contract.PredictionStats(1)).buyCount
      .mul((await contract.Predictions(1)).price)
      .mul(state.minerPercentage)
      .div(100)

    expect(await contract.Balances(miner1.address)).to.equal(
      miningFeeShare.add(minerReward).add(state.minerStakingFee),
    )

    await contract.connect(miner5).settleMiner(1, 5)

    expect((await contract.Validations(5, 1)).settled).to.be.true

    expect(await contract.Balances(miner5.address)).to.equal(
      miningFeeShare.add(minerReward),
    )

    expect((await contract.LockedFunds(miner5.address)).amount).to.equal(
      state.minerStakingFee,
    )

    await expect(contract.connect(miner5).settleMiner(1, 5)).to.be.revertedWith(
      "Miner already settled",
    )

    await expect(contract.connect(miner6).settleMiner(1, 6)).to.be.revertedWith(
      "Not miner",
    )

    await expect(contract.connect(miner7).settleMiner(2, 7)).to.be.revertedWith(
      "Not an active prediction",
    )
  })

  it("settles miner's accordingly when prediction lost", async function () {
    await ethers.provider.send("evm_increaseTime", [136000])

    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await contract.connect(miner2).submitClosingVote(1, 2, 1)

    await contract.connect(miner3).submitClosingVote(1, 3, 2)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1)

    await contract.connect(miner4).settleMiner(1, 4)

    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS)

    expect(await contract.Balances(miner1.address)).to.equal(miningFeeShare)

    expect((await contract.LockedFunds(miner1.address)).amount).to.equal(
      state.minerStakingFee,
    )

    expect(await contract.Balances(miner4.address)).to.equal(
      miningFeeShare.add(state.minerStakingFee),
    )
  })
})
