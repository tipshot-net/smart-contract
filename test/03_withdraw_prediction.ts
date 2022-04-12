import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Predictsea, PredictNFT } from "../typechain"
import state from "./variables"

describe("withdrawPrediction function", async function () {
  let contractOwner: SignerWithAddress
  let contract: Predictsea
  let minerNFT: PredictNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress
  let miner1: SignerWithAddress

  beforeEach(async function () {
    const Predictsea = await ethers.getContractFactory("Predictsea")
    ;[contractOwner, user1, user2, miner1] = await ethers.getSigners()
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
  })

  describe("seller withdraw prediction before it was mined", async function () {
    it("withdraws prediction from mining pool", async function () {
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
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1)
      expect(await contract.miningPool(0)).to.equal(1)
      expect(await contract.Balances(user1.address)).to.equal(0)
      await contract.connect(user1).withdrawPrediction(1)
      expect(await contract.miningPool(0)).to.equal(0)
      expect((await contract.Predictions(1)).state).to.equal(1) //withdrawn
      expect(await contract.Balances(user1.address)).to.equal(state.miningFee)
      await expect(
        contract.connect(user1).withdrawPrediction(1),
      ).to.be.revertedWith("Prediction already withdrawn!")
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1)
    })
  })

  it("should revert if non seller tries to withdraw prediction", async () => {
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
    await expect(
      contract.connect(user2).withdrawPrediction(1),
    ).to.be.revertedWith("Only prediction seller")
    expect(await contract.miningPool(0)).to.equal(1)
    expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1)
  })

  it("reverts if prediction to be withdrawn has already been assigned to a miner", async function () {
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
    await minerNFT.connect(contractOwner).increaseMintLimit(1)
    await minerNFT.connect(miner1).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
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
      contract.connect(user1).withdrawPrediction(1),
    ).to.be.revertedWith("Prediction already mined")
  })
})
