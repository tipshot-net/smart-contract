import { expect } from "chai"
import { ethers } from "hardhat"
const { BigNumber } = require("ethers")
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Update prediction", async function () {
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let minerNFT: MinerNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress
  let miner1: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot")
    ;[contractOwner, user1, user2, miner1] = await ethers.getSigners()
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
  })

  it("allows seller to update prediction data", async function () {
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
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await contract
      .connect(user1)
      .updatePrediction(
        1,
        "newipfshash123",
        "newkey123",
        _startTime + 3600,
        _endTime + 3600,
        300,
        ethers.utils.parseEther("20.0"),
      )

    const current = await contract.Predictions(1)
    expect(current.seller).to.equal(user1.address)
    expect(current.ipfsHash).to.equal("newipfshash123")
    expect(current.key).to.equal("newkey123")
    expect(BigNumber.from(current.createdAt)).to.be.closeTo(
      BigNumber.from(latestBlock.timestamp),
      5,
    )
    expect(current.startTime).to.equal(_startTime + 3600)
    expect(current.endTime).to.equal(_endTime + 3600)
    expect(current.odd).to.equal(300)
    expect(current.price).to.equal(ethers.utils.parseEther("0.0"))
    expect(await contract.miningPool(0)).to.equal(1)
    expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1)
    expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1)
    expect(
      await contract.connect(user1).getOwnedPredictionsLength(user1.address),
    ).to.equal(1)
  })

  it("reverts if prediction data updated by non seller", async function () {
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
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )

    await expect(
      contract
        .connect(user2)
        .updatePrediction(
          1,
          "newipfshash123",
          "newkey123",
          _startTime + 3600,
          _endTime + 3600,
          300,
          ethers.utils.parseEther("20.0"),
        ),
    ).to.be.revertedWith("Only prediction seller")
  })

  it("reverts if prediction to be updated has been assigned to a miner", async function () {
    const latestBlock = await ethers.provider.getBlock("latest")
    const _startTime = latestBlock.timestamp + 43200
    const _endTime = _startTime + 86400

    await minerNFT
      .connect(contractOwner)
      .setCost(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).whitelistUser(miner1.address)
    await minerNFT.connect(miner1).mint(miner1.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner1).approve(contract.address, 1)

    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("mining pool empty")

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

    await ethers.provider.send("evm_increaseTime", [14400])
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    await expect(
      contract
        .connect(user1)
        .updatePrediction(
          1,
          "newipfshash123",
          "newkey123",
          _startTime + 3600,
          _endTime + 3600,
          300,
          ethers.utils.parseEther("20.0"),
        ),
    ).to.be.revertedWith("Prediction already mined")
  })
})
