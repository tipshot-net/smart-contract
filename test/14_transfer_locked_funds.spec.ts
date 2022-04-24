import { expect } from "chai"
import { ethers } from "hardhat"
const { BigNumber } = require("ethers")
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Transfer locked funds", async function () {
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
  let miner9: SignerWithAddress

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
      miner9,
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
    await minerNFT.connect(contractOwner).whitelistUser(miner9.address)

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

    await minerNFT.connect(miner9).mint(miner9.address, {
      value: ethers.utils.parseEther("2.0"),
    })

    await minerNFT.connect(contractOwner).whitelistUser(miner1.address)

    await minerNFT.connect(miner1).mint(miner1.address, {
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
    await minerNFT.connect(miner9).approve(contract.address, 9)
    await minerNFT.connect(miner1).approve(contract.address, 10)

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

    await contract.connect(miner9).requestValidation(
      9, //tokenId
      "miner9_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner1).requestValidation(
      10, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await contract.connect(miner1).submitOpeningVote(1, 1, 1)

    await contract.connect(miner2).submitOpeningVote(1, 2, 1)

    await contract.connect(miner3).submitOpeningVote(1, 3, 1)

    await contract.connect(miner4).submitOpeningVote(1, 4, 1)

    await contract.connect(miner5).submitOpeningVote(1, 5, 1)

    await contract.connect(miner6).submitOpeningVote(2, 6, 1)
    await contract.connect(miner7).submitOpeningVote(2, 7, 1)
    await contract.connect(miner8).submitOpeningVote(2, 8, 1)
    await contract.connect(miner9).submitOpeningVote(2, 9, 1)
    await contract.connect(miner1).submitOpeningVote(2, 10, 1)

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

    await contract.connect(buyer1).purchasePrediction(2, "buyerkey1", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer2).purchasePrediction(2, "buyerkey2", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer3).purchasePrediction(2, "buyerkey3", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer4).purchasePrediction(2, "buyerkey4", {
      value: ethers.utils.parseEther("10.0"),
    })
    await contract.connect(buyer5).purchasePrediction(2, "buyerkey5", {
      value: ethers.utils.parseEther("10.0"),
    })

    await ethers.provider.send("evm_increaseTime", [136000])

    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await contract.connect(miner2).submitClosingVote(1, 2, 1)

    await contract.connect(miner3).submitClosingVote(1, 3, 2)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await contract.connect(miner5).submitClosingVote(1, 5, 2)

    await contract.connect(miner6).submitClosingVote(2, 6, 2)

    await contract.connect(miner7).submitClosingVote(2, 7, 2)

    await contract.connect(miner8).submitClosingVote(2, 8, 2)

    await contract.connect(miner9).submitClosingVote(2, 9, 2)

    await contract.connect(miner1).submitClosingVote(2, 10, 1)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1)

    await contract.connect(miner4).settleMiner(1, 4)
  })

  it("it locks miner's funds if miners vote isn't in agreement with majority", async function () {
    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS)

    expect(await contract.Balances(miner1.address)).to.equal(
      miningFeeShare.mul(2),
    )

    expect((await contract.LockedFunds(miner1.address)).amount).to.equal(
      state.minerStakingFee,
    )

    expect(
      (await contract.LockedFunds(miner1.address)).totalInstances,
    ).to.equal(1)

    const currently = (await ethers.provider.getBlock("latest")).timestamp

    expect(
      (await contract.LockedFunds(miner1.address)).lastPushDate,
    ).to.be.closeTo(BigNumber.from(currently), BigNumber.from(5))

    expect(
      (await contract.LockedFunds(miner1.address)).releaseDate.sub(currently),
    ).to.be.closeTo(BigNumber.from(2592000), BigNumber.from(5))

    await expect(
      contract.connect(miner1).transferLockedFunds(state.minerStakingFee),
    ).to.be.revertedWith("Assets still frozen")
  })

  it("transfers funds to main balance after release date", async function () {
    await ethers.provider.send("evm_increaseTime", [2592000])

    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS)

    await contract.connect(miner1).transferLockedFunds(state.minerStakingFee)

    expect(await contract.Balances(miner1.address)).to.equal(
      miningFeeShare.mul(2).add(state.minerStakingFee),
    )

    expect((await contract.LockedFunds(miner1.address)).amount).to.equal(0)
  })

  it("reverts if contract is locked", async function () {
    await contract.connect(contractOwner).lock()
    await ethers.provider.send("evm_increaseTime", [2592000])
    await expect(contract.connect(miner1).transferLockedFunds(state.minerStakingFee)).to.be.revertedWith("Contract in locked state")
  })

  it("reverts if amount to be transfered greater than locked amount", async function () {
    await ethers.provider.send("evm_increaseTime", [2592000])

    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS)

    await expect(
      contract
        .connect(miner1)
        .transferLockedFunds(state.minerStakingFee.add(1)),
    ).to.be.revertedWith("Not enough balance")
  })

  it("extends release date by a month, on each vote disagreement with majority", async function () {
    await contract.connect(miner1).settleMiner(2, 10)

    expect((await contract.LockedFunds(miner1.address)).amount).to.equal(
      state.minerStakingFee.mul(2),
    )

    expect(
      (await contract.LockedFunds(miner1.address)).totalInstances,
    ).to.equal(2)

    const currently = (await ethers.provider.getBlock("latest")).timestamp

    expect(
      (await contract.LockedFunds(miner1.address)).lastPushDate,
    ).to.be.closeTo(BigNumber.from(currently), BigNumber.from(5))

    expect(
      (await contract.LockedFunds(miner1.address)).releaseDate.sub(currently),
    ).to.be.closeTo(BigNumber.from(5184000), BigNumber.from(5))

    await ethers.provider.send("evm_increaseTime", [2592000])

    await expect(
      contract.connect(miner1).transferLockedFunds(state.minerStakingFee),
    ).to.be.revertedWith("Assets still frozen")

    await ethers.provider.send("evm_increaseTime", [2592000])

    await contract.connect(miner1).transferLockedFunds(state.minerStakingFee)

    expect((await contract.LockedFunds(miner1.address)).amount).to.equal(
      state.minerStakingFee,
    )
  })
})
