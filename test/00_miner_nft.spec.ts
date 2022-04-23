import { expect } from "chai"
import { ethers } from "hardhat"
const { BigNumber } = require("ethers")
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { MinerNFT } from "../typechain"


describe("miner NFT contract", async function () {
  let contractOwner: SignerWithAddress
  let contract: MinerNFT
  let user1: SignerWithAddress
  let user2: SignerWithAddress

  beforeEach(async function () {
    const minerNFT = await ethers.getContractFactory("MinerNFT")
    ;[contractOwner, user1, user2] = await ethers.getSigners()
    contract = await minerNFT.deploy("Tipshot-Miner", "TMT", "https://ipfs.io/kdkij99u9nsk/")
    await contract.deployed()
  })

  it("sets state variable in constructor", async function () {
    expect(await contract.name()).to.equal("Tipshot-Miner");
    expect(await contract.symbol()).to.equal("TMT");
    expect(await contract.baseURI()).to.equal("https://ipfs.io/kdkij99u9nsk/");
  })

  it("allows only contract owner to set cost", async function () {
    expect(await contract.cost()).to.equal(0)
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("10.0"));
    expect(await contract.cost()).to.equal(ethers.utils.parseEther("10.0"));
    await expect(contract.connect(user1).setCost(ethers.utils.parseEther("1.0"))).to.be.revertedWith("Unauthorized access")
  })

  it("allows only contract owner to set base URI", async function () {
    await contract.connect(contractOwner).setBaseURI("https://ipfs.io/newbaseurl/");
    expect(await contract.baseURI()).to.equal("https://ipfs.io/newbaseurl/");
    await expect(contract.connect(user1).setBaseURI("https://ipfs.io/falseuri/")).to.be.revertedWith("Unauthorized access")

  })

  it("allows only contract owner to set base extension", async function () {
    expect(await contract.baseExtension()).to.equal(".json");
    await contract.connect(contractOwner).setBaseExtension(".yml");
    expect(await contract.baseExtension()).to.equal(".yml");
    await expect(contract.connect(user1).setBaseExtension(".txt")).to.be.revertedWith("Unauthorized access")
  })

  it("allows only contract owner to whitelist user", async function () {
    expect(await contract.whitelisted(user1.address)).to.be.false;
    await contract.connect(contractOwner).whitelistUser(user1.address);
    expect(await contract.whitelisted(user1.address)).to.be.true;
    await expect(contract.connect(user1).whitelistUser(user2.address)).to.be.revertedWith("Unauthorized access")
  })

  it("allows only contract owner to remove whitelist user", async function () {
    await contract.connect(contractOwner).whitelistUser(user1.address);
    expect(await contract.whitelisted(user1.address)).to.be.true;
    await contract.connect(contractOwner).removeWhitelistUser(user1.address);
    expect(await contract.whitelisted(user1.address)).to.be.false;
    await expect(contract.connect(user2).removeWhitelistUser(user1.address)).to.be.revertedWith("Unauthorized access")
  })

  it("allows only whitelisted user to mint once", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("2.0"));
    await expect(contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("2.0")
    })).to.be.revertedWith("MinerNFT: Not whitelisted")
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await contract.connect(user1).mint(user2.address, {
      value: ethers.utils.parseEther("2.0")
    });
    expect(await contract.ownerOf(1)).to.equal(user2.address);
    await expect(contract.connect(user1).mint(user2.address)).to.be.revertedWith("MinerNFT: Not whitelisted")
  })

  it("reverts if eth sent for mint is below or above cost price", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("2.0"));
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await expect(contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("3.0")
    })).to.be.revertedWith("ETH sent must be exactly selling fee")

    await expect(contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("1.0")
    })).to.be.revertedWith("ETH sent must be exactly selling fee")

    await contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("2.0")
    });
    expect(await contract.ownerOf(1)).to.equal(user1.address);
  })

  it("reverts if contract is locked", async function () {
    await contract.connect(contractOwner).lock();
    await expect(contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("3.0")
    })).to.be.revertedWith("MinerNFT: Contract in locked state")

  })

  
  it("allows only contract owner to withdraw", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("10.0"));
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await contract.connect(user1).mint(user2.address, {
      value: ethers.utils.parseEther("10.0")
    });
    expect(await ethers.provider.getBalance(contract.address)).to.equal(ethers.utils.parseEther("10.0"))
    await expect(contract.connect(user1).withdraw()).to.be.revertedWith("Unauthorized access")
    const prevBalance = await ethers.provider.getBalance(contractOwner.address);
    const tx = await contract.connect(contractOwner).withdraw();
    const gasinfo = await tx.wait()
    const fee = gasinfo.gasUsed.mul(gasinfo.effectiveGasPrice)
    expect(await ethers.provider.getBalance(contractOwner.address)).to.equal(prevBalance.add(ethers.utils.parseEther("10.0")).sub(fee))
  })

  it("return contents of wallet ", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("2.0"));
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("2.0")
    });
    expect(await contract.walletOfOwner(user1.address)).to.deep.equal([BigNumber.from(1)])
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("2.0")
    });
    expect(await contract.walletOfOwner(user1.address)).to.deep.equal([BigNumber.from(1), BigNumber.from(2)])
  })

  it("returns token URI", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("2.0"));
    await contract.connect(contractOwner).whitelistUser(user1.address);
    await contract.connect(user1).mint(user1.address, {
      value: ethers.utils.parseEther("2.0")
    });
    expect(await contract.tokenURI(1)).to.equal("https://ipfs.io/kdkij99u9nsk/1.json")
  })

  it("allows contract owner to mint without fee & whitelist", async function () {
    await contract.connect(contractOwner).setCost(ethers.utils.parseEther("2.0"));
    await contract.connect(contractOwner).mint(user1.address);
    expect(await contract.ownerOf(1)).to.equal(user1.address);
  })


})