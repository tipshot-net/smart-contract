import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Settle seller", async function () {
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

    await ethers.provider.send("evm_increaseTime", [136000])
  })

  it("reverts if non seller tries to call", async function () {
    await expect(contract.connect(user2).settleSeller(1)).to.be.revertedWith(
      "Only prediction seller",
    )
  })

  it("reverts if not concluded by a miner", async function () {
    await expect(contract.connect(user1).settleSeller(1)).to.be.revertedWith(
      "Prediction not concluded",
    )
  })

  it("reverts if prediction lost", async function () {
    await contract.connect(miner1).submitClosingVote(1, 1, 2)

    await contract.connect(miner2).submitClosingVote(1, 2, 2)

    await contract.connect(miner3).submitClosingVote(1, 3, 2)

    await contract.connect(miner4).submitClosingVote(1, 4, 2)

    await contract.connect(miner5).submitClosingVote(1, 5, 2)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1)

    await expect(contract.connect(user1).settleSeller(1)).to.be.revertedWith(
      "Prediction lost!",
    )
  })

  it("allows seller withdraw earnings when prediction won", async function () {
    await contract.connect(miner1).submitClosingVote(1, 1, 1)

    await contract.connect(miner2).submitClosingVote(1, 2, 1)

    await contract.connect(miner3).submitClosingVote(1, 3, 1)

    await contract.connect(miner4).submitClosingVote(1, 4, 1)

    await contract.connect(miner5).submitClosingVote(1, 5, 1)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(1, 1)

    expect((await contract.Predictions(1)).withdrawnEarnings).to.be.false

    await contract.connect(user1).settleSeller(1)

    let minersReward = (await contract.PredictionStats(1)).buyCount
      .mul((await contract.Predictions(1)).price)
      .mul(state.minerPercentage)
      .div(100)
      .mul(state.MAX_VALIDATORS)

    expect(await contract.Balances(user1.address)).to.equal(
      (await contract.PredictionStats(1)).buyCount
        .mul((await contract.Predictions(1)).price)
        .sub(minersReward),
    )

    expect((await contract.Predictions(1)).withdrawnEarnings).to.be.true

    await expect(contract.connect(user1).settleSeller(1)).to.be.revertedWith(
      "Earnings withdrawn",
    )
  })
})
