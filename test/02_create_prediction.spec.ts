import { expect } from "chai"
import { ethers } from "hardhat"
const { BigNumber } = require("ethers")
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Create prediction", async function () {
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let user1: SignerWithAddress
  let user2: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot")
    ;[contractOwner, user1, user2] = await ethers.getSigners()
    contract = await Tipshot.deploy()
    await contract.deployed()

    const MinerNFT = await ethers.getContractFactory("MinerNFT")
    const minerNFT = await MinerNFT.deploy(
      "Tipshot-Miner",
      "TMT",
      "https://ipfs.io/kdkij99u9nsk/",
    )
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

  describe("seller creates prediction", async function () {
    it("sets all prediction data", async function () {
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
      const current = await contract.Predictions(1)
      expect(current.seller).to.equal(user1.address)
      expect(current.ipfsHash).to.equal("hellothere123")
      expect(current.key).to.equal("hithere123")
      expect(BigNumber.from(current.createdAt)).to.be.closeTo(
        BigNumber.from(latestBlock.timestamp),
        5,
      )
      expect(current.startTime).to.equal(_startTime)
      expect(current.endTime).to.equal(_endTime)
      expect(current.odd).to.equal(200)
      expect(current.price).to.equal(ethers.utils.parseEther("0.0"))
      expect(await contract.miningPool(0)).to.equal(1)
      expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1)
      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(1)
      expect(
        await contract.connect(user1).getOwnedPredictionsLength(user1.address),
      ).to.equal(1)
    })

    //time considerations

    it("should revert if start time is less than 8 hours from now", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 21600
      const _endTime = _startTime + 86400
      await expect(
        contract
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
          ),
      ).to.be.revertedWith("Doesn't meet time requirements")
    })

    it("should revert if end time is less than start time", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = latestBlock.timestamp + 36000
      await expect(
        contract
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
          ),
      ).to.be.revertedWith("End time less than start time")
    })

    it("should revert if start time greater than 24 hours from now", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 90000
      const _endTime = _startTime + 86400

      await expect(
        contract
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
          ),
      ).to.be.revertedWith("Doesn't meet time requirements")
    })

    it("should revert if (endtime - starttime) > 48 hours", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = _startTime + 180000

      await expect(
        contract
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
          ),
      ).to.be.revertedWith("Doesn't meet time requirements")
    })

    //odds consideration

    it("should revert if odd is less that or equal to 1", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = _startTime + 86400
      await expect(
        contract
          .connect(user1)
          .createPrediction(
            "hellothere123",
            "hithere123",
            _startTime,
            _endTime,
            100,
            ethers.utils.parseEther("10.0"),
            {
              value: state.miningFee,
            },
          ),
      ).to.be.revertedWith("Odd must be greater than 1")
    })

    it("reverts if sent eth is less than (miningFee + sellerStakingFee)", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = _startTime + 86400

      await expect(
        contract
          .connect(user1)
          .createPrediction(
            "hellothere123",
            "hithere123",
            _startTime,
            _endTime,
            200,
            ethers.utils.parseEther("10.0"),
            {
              value: state.miningFee.sub(ethers.utils.parseEther("2.0")),
            },
          ),
      ).to.be.revertedWith("Insufficient balance")
    })

    it("deposits excess fee in wallet", async function () {
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
            value: state.miningFee.add(ethers.utils.parseEther("2.0")),
          },
        )

      expect(await contract.Balances(user1.address)).to.equal(
        ethers.utils.parseEther("2.0"),
      )
    })

    it("deducts from wallet balance if sent eth is not enough", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = _startTime + 86400
      let tx = {
        to: contract.address,
        value: ethers.utils.parseEther("5.0"),
      }

      await user1.sendTransaction(tx)
      expect(await contract.Balances(user1.address)).to.be.equal(
        ethers.utils.parseEther("5.0"),
      )
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
            value: state.miningFee.sub(ethers.utils.parseEther("2.0")),
          },
        )

      const current = await contract.Predictions(1)
      expect(current.seller).to.equal(user1.address)
      expect(current.ipfsHash).to.equal("hellothere123")
      expect(current.key).to.equal("hithere123")
      expect(BigNumber.from(current.createdAt)).to.be.closeTo(
        BigNumber.from(latestBlock.timestamp),
        5,
      )
      expect(current.startTime).to.equal(_startTime)
      expect(current.endTime).to.equal(_endTime)
      expect(current.odd).to.equal(200)
      expect(await contract.miningPool(0)).to.equal(1)
      expect(await contract.OwnedPredictions(user1.address, 0)).to.equal(1)

      expect(await contract.Balances(user1.address)).to.be.equal(
        ethers.utils.parseEther("3.0"),
      )
    })

    it("creates multiple predictions in mining pool", async function () {
      const latestBlock = await ethers.provider.getBlock("latest")
      const _startTime = latestBlock.timestamp + 43200
      const _endTime = _startTime + 86400
      for (let index = 0; index < 10; index++) {
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
      }

      expect(await contract.connect(user1).getMiningPoolLength()).to.equal(10)
      expect(await contract.miningPool(2)).to.equal(3)
      expect(await contract.miningPool(4)).to.equal(5)
      expect(await contract.miningPool(8)).to.equal(9)
    })
  })
})
