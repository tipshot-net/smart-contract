import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Tipshot, MinerNFT } from "../typechain"
import state from "./variables"

describe("Recieve & withdraw funds", async function () {
  let contractOwner: SignerWithAddress
  let contract: Tipshot
  let user1: SignerWithAddress
  let user2: SignerWithAddress

  beforeEach(async function () {
    const Tipshot = await ethers.getContractFactory("Tipshot");
    [contractOwner, user1, user2] = await ethers.getSigners()
    contract = await Tipshot.deploy()
    await contract.deployed()

    const MinerNFT = await ethers.getContractFactory("MinerNFT")
    const minerNFT = await MinerNFT.deploy("Tipshot-Miner", "TMT", "https://ipfs.io/kdkij99u9nsk/")
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

  it("adds funds to user's balances", async function () {
    let tx = {
      to: contract.address,
      value: ethers.utils.parseEther("5.0"),
    }

    await user1.sendTransaction(tx)
    expect(await contract.Balances(user1.address)).to.equal(ethers.utils.parseEther("5.0"));
  })

  it("withdraws funds from balance", async function () {
    let prevBalance = await ethers.provider.getBalance(user1.address);
    let payload = {
      to: contract.address,
      value: ethers.utils.parseEther("5.0"),
    }
    const tx1 = await user1.sendTransaction(payload)
    let gasinfo1 = await tx1.wait()
    let tf1 = gasinfo1.gasUsed.mul(gasinfo1.effectiveGasPrice)
    const tx2 = await contract.connect(user1).withdrawFunds(ethers.utils.parseEther("4.0"))
    let gasinfo2 = await tx2.wait();

    let tf2 = gasinfo2.gasUsed.mul(gasinfo2.effectiveGasPrice)
    let totalTransactionFees = tf1.add(tf2)
    
    expect(await contract.Balances(user1.address)).to.equal(ethers.utils.parseEther("1.0"))
    expect((await ethers.provider.getBalance(user1.address))
      .add(totalTransactionFees))
      .to.equal(prevBalance.sub(ethers.utils.parseEther("1.0")))
  })

  it("reverts if amount to be withdrawn greater than balance", async function () {
    let payload = {
      to: contract.address,
      value: ethers.utils.parseEther("5.0"),
    }
    await user1.sendTransaction(payload)

    await expect(contract.connect(user1).withdrawFunds(ethers.utils.parseEther("5.1"))).to.be.revertedWith("Not enough balance")
  })


})