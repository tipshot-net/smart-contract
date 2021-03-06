import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Request validation", async function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000"
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let minerNFT: MinerNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress
  let miner1: SignerWithAddress
  let miner2: SignerWithAddress
  let miner3: SignerWithAddress
  let miner4: SignerWithAddress
  let miner5: SignerWithAddress
  let miner6: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot")
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
      .connect(user2)
      .createPrediction(
        "newipfshash123",
        "newkey123",
        _startTime + 14400,
        _endTime + 14400,
        300,
        ethers.utils.parseEther("20.0"),
        {
          value: state.miningFee,
        },
      )

    await minerNFT
      .connect(contractOwner)
      .setCost(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).whitelistUser(miner1.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner2.address)
    await minerNFT.connect(miner1).mint(miner1.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner2).mint(miner2.address, {
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner1).approve(contract.address, 1)
    await minerNFT.connect(miner2).approve(contract.address, 2)
  })

  it("assigns prediction to miner", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    expect((await contract.Validations(1, 1)).assigned).to.be.false
    expect((await contract.PredictionStats(1)).validatorCount).to.equal(0)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(0)
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )

    expect(await minerNFT.connect(contractOwner).ownerOf(1)).to.equal(
      contract.address,
    )
    expect((await contract.Validations(1, 1)).assigned).to.be.true
    expect((await contract.PredictionStats(1)).validatorCount).to.equal(1)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).id).to.equal(1)
    expect(
      (await contract.OwnedValidations(miner1.address, 0)).tokenId,
    ).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).key).to.equal(
      "miner1_key",
    )
  })

  it("reverts if contract is locked", async function () {
    await contract.connect(contractOwner).lock()
    await ethers.provider.send("evm_increaseTime", [14400])
    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("Contract in locked state")
  })

  it("reverts if eth sent less than miner staking fee", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee.sub(ethers.utils.parseEther("2.0")),
        },
      ),
    ).to.be.revertedWith("Insufficient balance")
  })

  it("deducts from balance if eth sent is less than mining fee", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    let tx = {
      to: contract.address,
      value: ethers.utils.parseEther("5.0"),
    }
    await miner1.sendTransaction(tx)

    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee.sub(ethers.utils.parseEther("2.0")),
      },
    )

    expect(await contract.Balances(miner1.address)).to.equal(
      ethers.utils.parseEther("3.0"),
    )
  })

  it("deposits excess eth in balance", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])

    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee.add(ethers.utils.parseEther("2.0")),
      },
    )

    expect(await contract.Balances(miner1.address)).to.equal(
      ethers.utils.parseEther("2.0"),
    )
  })

  it("reverts if miner doesn't own nft", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    await expect(
      contract.connect(user1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("Doesn't own NFT")
  })

  it("reverts if miner doesn't grant NFT transfer approval", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    await minerNFT.connect(miner1).approve(zeroAddress, 1)
    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("ERC721: transfer caller is not owner nor approved")
  })

  it("assigns the next prediction, if the previous is withdrawn", async function () {
    await contract.connect(user1).withdrawPrediction(1)
    await ethers.provider.send("evm_increaseTime", [14400])
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )
    expect((await contract.Validations(1, 1)).assigned).to.be.false
    expect((await contract.Validations(1, 2)).assigned).to.be.true
    expect((await contract.PredictionStats(1)).validatorCount).to.equal(0)
    expect((await contract.PredictionStats(2)).validatorCount).to.equal(1)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).id).to.equal(2)
    expect(
      (await contract.OwnedValidations(miner1.address, 0)).tokenId,
    ).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).key).to.equal(
      "miner1_key",
    )
  })

  it("reverts if mining pool is empty -> all predictions withdrawn", async function () {
    await contract.connect(user1).withdrawPrediction(1)
    await contract.connect(user2).withdrawPrediction(2)
    await ethers.provider.send("evm_increaseTime", [14400])

    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("Mining pool currently empty")
  })

  it("skips to next prediction if current prediction starts in less than 2 hours", async function () {
    await ethers.provider.send("evm_increaseTime", [37000])
    await contract.connect(miner1).requestValidation(
      1, //tokenId
      "miner1_key", //key
      {
        value: state.minerStakingFee,
      },
    )
    expect((await contract.Validations(1, 1)).assigned).to.be.false
    expect((await contract.Validations(1, 2)).assigned).to.be.true
    expect((await contract.PredictionStats(1)).validatorCount).to.equal(0)
    expect((await contract.PredictionStats(2)).validatorCount).to.equal(1)
    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).id).to.equal(2)
    expect(
      (await contract.OwnedValidations(miner1.address, 0)).tokenId,
    ).to.equal(1)
    expect((await contract.OwnedValidations(miner1.address, 0)).key).to.equal(
      "miner1_key",
    )
  })

  it("reverts if prediction to be assigned is not cooled down", async function () {
    await expect(
      contract.connect(miner1).requestValidation(
        1, //tokenId
        "miner1_key", //key
        {
          value: state.minerStakingFee,
        },
      ),
    ).to.be.revertedWith("Not available for mining")
  })

  it("moves to the next prediction after max validators attained", async function () {
    await ethers.provider.send("evm_increaseTime", [14400])
    await minerNFT.connect(contractOwner).whitelistUser(miner3.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner4.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner5.address)
    await minerNFT.connect(contractOwner).whitelistUser(miner6.address)

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

    await minerNFT.connect(miner3).approve(contract.address, 3)
    await minerNFT.connect(miner4).approve(contract.address, 4)
    await minerNFT.connect(miner5).approve(contract.address, 5)
    await minerNFT.connect(miner6).approve(contract.address, 6)

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

    expect((await contract.PredictionStats(1)).validatorCount).to.equal(5)
    expect((await contract.PredictionStats(2)).validatorCount).to.equal(1)
    expect((await contract.OwnedValidations(miner6.address, 0)).key).to.equal(
      "miner6_key",
    )
    expect(await contract.getMiningPoolLength()).to.equal(2)
    expect(await contract.miningPool(0)).to.equal(0)
    expect(await contract.miningPool(1)).to.equal(2)
  })
})
