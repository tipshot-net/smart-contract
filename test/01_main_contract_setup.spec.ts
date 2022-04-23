import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("set up contract", async function () {
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let user1: SignerWithAddress
  let user2: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot")
    ;[contractOwner, user1, user2] = await ethers.getSigners()
    contract = await Tipshot.deploy()
    await contract.deployed()
  })

  describe("ownership & variable setup", async function () {
    it("should set deployer as owner", async function () {
      expect(await contract.owner()).to.equal(contractOwner.address)
    })

    it("should have correct variable set by owner", async function () {
      await contract
        .connect(contractOwner)
        .setVariables(
          state.miningFee,
          state.minerStakingFee,
          state.minerPercentage,
        )
      expect(await contract.freeTipsQuota()).to.equal(0)
      await contract.connect(contractOwner).setFreeTipsQuota(100)
      expect(await contract.freeTipsQuota()).to.equal(100)
      expect(await contract.miningFee()).to.equal(state.miningFee)
      expect(await contract.minerStakingFee()).to.equal(state.minerStakingFee)
      expect(await contract.minerPercentage()).to.equal(state.minerPercentage)
    })

    it("should revert if variable set by non owner", async function () {
      await expect(
        contract
          .connect(user1)
          .setVariables(
            state.miningFee,
            state.minerStakingFee,
            state.minerPercentage,
          ),
      ).to.be.revertedWith("Unauthorized access")
    })

    it("should allow owner set NFT address", async function () {
      const MinerNFT = await ethers.getContractFactory("MinerNFT")
      const minerNFT = await MinerNFT.deploy(
        "Tipshot-Miner",
        "TMT",
        "https://ipfs.io/kdkij99u9nsk/",
      )
      await minerNFT.deployed()
      await contract.connect(contractOwner).setNftAddress(minerNFT.address)
      expect(await contract.NFT_CONTRACT_ADDRESS()).to.equal(minerNFT.address)
    })

    it("should revert if non owner set NFT address", async function () {
      const MinerNFT = await ethers.getContractFactory("MinerNFT")
      const minerNFT = await MinerNFT.deploy(
        "Tipshot-Miner",
        "TMT",
        "https://ipfs.io/kdkij99u9nsk/",
      )
      await minerNFT.deployed()
      await expect(
        contract.connect(user1).setNftAddress(minerNFT.address),
      ).to.be.revertedWith("Unauthorized access")
    })
  })

  describe("access features", async function () {
    it("should allow owner lock & unlock contract", async function () {
      await contract.connect(contractOwner).lock()
      expect(await contract.locked()).to.equal(true)
      await contract.connect(contractOwner).unlock()
      expect(await contract.locked()).to.equal(false)
    })

    it("should revert if contract locked by non owner", async function () {
      await expect(contract.connect(user1).lock()).to.be.revertedWith(
        "Unauthorized access",
      )
    })

    it("should allow owner to nominate new owner & nominated owner can take ownership", async function () {
      await contract.connect(contractOwner).nominateNewOwner(user1.address)
      expect(await contract.nominatedOwner()).to.equal(user1.address)
      await contract.connect(user1).transferOwnership()
      expect(await contract.owner()).to.equal(user1.address)
    })

    it("should revert if non owner nominates new owner", async function () {
      await expect(
        contract.connect(user1).nominateNewOwner(user2.address),
      ).to.be.revertedWith("Unauthorized access")
    })

    it("updates user's profile", async function () {
      expect((await contract.User(user1.address)).profile).to.equal("")
      expect((await contract.User(user1.address)).key).to.equal("")

      await contract.connect(user1).addProfile("myprofiledata", "mykey")

      expect((await contract.User(user1.address)).profile).to.equal(
        "myprofiledata",
      )
      expect((await contract.User(user1.address)).key).to.equal("mykey")
    })
  })
})
