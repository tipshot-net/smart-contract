import { expect } from "chai"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Predictsea, PredictNFT } from "../typechain"
import state from "./variables"

describe("Paid tips tests", async function () {
  const zeroAddress = "0x0000000000000000000000000000000000000000"
  let contractOwner: SignerWithAddress
  let contract: Predictsea
  let minerNFT: PredictNFT
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
    const Predictsea = await ethers.getContractFactory("Predictsea")
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

    await minerNFT
      .connect(contractOwner)
      .setSellingPrice(ethers.utils.parseEther("2.0"))
    await minerNFT.connect(contractOwner).increaseMintLimit(8)
    await minerNFT.connect(miner1).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner2).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner3).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner4).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    await minerNFT.connect(miner5).whitelist({
      value: ethers.utils.parseEther("2.0"),
    })
    

    await minerNFT.connect(miner1).mintToken("http://ipfs.io/json1")
    await minerNFT.connect(miner2).mintToken("http://ipfs.io/json2")
    await minerNFT.connect(miner3).mintToken("http://ipfs.io/json3")
    await minerNFT.connect(miner4).mintToken("http://ipfs.io/json4")
    await minerNFT.connect(miner5).mintToken("http://ipfs.io/json5")
    
    
  })

  it("only allows paid tips after 10 free tips", async function () {
    for (let index = 1; index <= 11; index++) {
      await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        (await ethers.provider.getBlock("latest")).timestamp + 43200,
        (await ethers.provider.getBlock("latest")).timestamp + 129600,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )
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

    
    await contract.connect(miner1).submitOpeningVote(index, 1, 1)

    await contract.connect(miner2).submitOpeningVote(index, 2, 1)

    await contract.connect(miner3).submitOpeningVote(index, 3, 1)

    await contract.connect(miner4).submitOpeningVote(index, 4, 1)

    await contract.connect(miner5).submitOpeningVote(index, 5, 1)

    if(index == 11){
      await contract.connect(buyer1).purchasePrediction(index, "buyerkey1", {
        value: ethers.utils.parseEther("10.0")
      })
      await contract.connect(buyer2).purchasePrediction(index, "buyerkey2", {
        value: ethers.utils.parseEther("10.0")
      })
      await contract.connect(buyer3).purchasePrediction(index, "buyerkey3", {
        value: ethers.utils.parseEther("10.0")
      })
      await contract.connect(buyer4).purchasePrediction(index, "buyerkey4", {
        value: ethers.utils.parseEther("10.0")
      })
      await contract.connect(buyer5).purchasePrediction(index, "buyerkey5", {
        value: ethers.utils.parseEther("10.0")
      })
    }

    await ethers.provider.send("evm_increaseTime", [136000]);

    await contract.connect(miner1).submitClosingVote(index, 1, 1)

    await contract.connect(miner2).submitClosingVote(index, 2, 1)

    await contract.connect(miner3).submitClosingVote(index, 3, 1)

    await contract.connect(miner4).submitClosingVote(index, 4, 1)

    await contract.connect(miner5).submitClosingVote(index, 5, 1)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(index, 1);

    await contract.connect(miner1).withdrawFunds(state.minerStakingFee);

     if(index == 11){
      await contract.connect(user1).settleSeller(11);
     }

    
    }

    let minersReward = (await contract.PredictionStats(11)).buyCount.mul((await contract.Predictions(11)).price).mul(state.minerPercentage).div(100).mul(state.MAX_VALIDATORS);

    let minerReward = (await contract.PredictionStats(11)).buyCount.mul((await contract.Predictions(11)).price).mul(state.minerPercentage).div(100);

    let miningFeeShare = (await contract.miningFee()).div(state.MAX_VALIDATORS).mul(11)

    expect(await contract.Balances(miner1.address)).to.equal(miningFeeShare.add(minerReward))

    expect(await contract.Balances(user1.address)).to.equal((await contract.PredictionStats(11)).buyCount.mul((await contract.Predictions(11)).price).sub(minersReward))

    expect((await contract.Predictions(11)).withdrawnEarnings).to.be.true;

    await expect(contract.connect(user1).settleSeller(11)).to.be.revertedWith("Earnings withdrawn");


    expect((await contract.Predictions(1)).price).to.equal(0)
    expect((await contract.Predictions(4)).price).to.equal(0)
    expect((await contract.Predictions(10)).price).to.equal(0)
    expect((await contract.Predictions(11)).price).to.equal(ethers.utils.parseEther("10.0"))
  })

  it("only allows paid tips if tipster has profitable history", async function () {
    for (let index = 1; index <= 11; index++) {
      await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        (await ethers.provider.getBlock("latest")).timestamp + 43200,
        (await ethers.provider.getBlock("latest")).timestamp + 129600,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )
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

    
    await contract.connect(miner1).submitOpeningVote(index, 1, 1)

    await contract.connect(miner2).submitOpeningVote(index, 2, 1)

    await contract.connect(miner3).submitOpeningVote(index, 3, 1)

    await contract.connect(miner4).submitOpeningVote(index, 4, 1)

    await contract.connect(miner5).submitOpeningVote(index, 5, 1)

    expect(await contract.getActivePoolLength()).to.equal(1)
    expect(await contract.activePool(0)).to.equal(index)

    await ethers.provider.send("evm_increaseTime", [136000]);

    let outcome = 2;

    if(index > 5 ){
      outcome = 1
    }

    await contract.connect(miner1).submitClosingVote(index, 1, outcome)

    await contract.connect(miner2).submitClosingVote(index, 2, outcome)

    await contract.connect(miner3).submitClosingVote(index, 3, outcome)

    await contract.connect(miner4).submitClosingVote(index, 4, outcome)

    await contract.connect(miner5).submitClosingVote(index, 5, outcome)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(index, 1);

      
    }

    await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        (await ethers.provider.getBlock("latest")).timestamp + 43200,
        (await ethers.provider.getBlock("latest")).timestamp + 129600,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )
    expect(await contract.getOwnedPredictionsLength(user1.address)).to.equal(7)
    
    expect((await contract.Predictions(1)).price).to.equal(0)
    expect((await contract.Predictions(4)).price).to.equal(0)
    expect((await contract.Predictions(10)).price).to.equal(0)
    expect((await contract.Predictions(11)).price).to.equal(0)
    expect((await contract.Predictions(12)).price).to.equal(ethers.utils.parseEther("10.0"))
  })

  it("refunds buyer if prediction lost in a paid tip", async function () {
    for (let index = 1; index <= 11; index++) {
      await contract
      .connect(user1)
      .createPrediction(
        "hellothere123",
        "hithere123",
        (await ethers.provider.getBlock("latest")).timestamp + 43200,
        (await ethers.provider.getBlock("latest")).timestamp + 129600,
        200,
        ethers.utils.parseEther("10.0"),
        {
          value: state.miningFee,
        },
      )
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

    
    await contract.connect(miner1).submitOpeningVote(index, 1, 1)

    await contract.connect(miner2).submitOpeningVote(index, 2, 1)

    await contract.connect(miner3).submitOpeningVote(index, 3, 1)

    await contract.connect(miner4).submitOpeningVote(index, 4, 1)

    await contract.connect(miner5).submitOpeningVote(index, 5, 1)

    
    
    let outcome = 1
    if(index == 11){
      outcome = 2
      let tx = {
        to: contract.address,
        value: ethers.utils.parseEther("5.0") 
       };
  
      await buyer1.sendTransaction(tx);
      await contract.connect(buyer1).purchasePrediction(index, "mykey", {
        value: ethers.utils.parseEther("5.0")
      })
      await contract.connect(buyer2).purchasePrediction(index, "buyerkey2", {
        value: ethers.utils.parseEther("10.0")
      })
      await expect(contract.connect(buyer3).purchasePrediction(index, "mykey", {
        value: ethers.utils.parseEther("5.0")
      })).to.be.revertedWith("Insufficient balance");
    }

    await ethers.provider.send("evm_increaseTime", [136000]);

    await contract.connect(miner1).submitClosingVote(index, 1, outcome)

    await contract.connect(miner2).submitClosingVote(index, 2, outcome)

    await contract.connect(miner3).submitClosingVote(index, 3, outcome)

    await contract.connect(miner4).submitClosingVote(index, 4, outcome)

    await contract.connect(miner5).submitClosingVote(index, 5, outcome)

    await ethers.provider.send("evm_increaseTime", [18000])

    await contract.connect(miner1).settleMiner(index, 1);

      
    }

    expect((await contract.OwnedValidations(miner1.address, 0)).id).to.equal(11);

    expect(await contract.getOwnedValidationsLength(miner1.address)).to.equal(1)

    expect(await contract.getOwnedValidationsLength(miner2.address)).to.equal(11)

    expect((await contract.Predictions(11)).price).to.equal(ethers.utils.parseEther("10.0"))

    expect(await contract.Balances(buyer1.address)).to.equal(0);

    expect((await contract.Purchases(buyer1.address, 11)).purchased).to.be.true;

    expect((await contract.Purchases(buyer2.address, 11)).purchased).to.be.true;

    expect(await contract.Balances(buyer2.address)).to.equal(0)


    await contract.connect(buyer2).refundBuyer(11);

    expect(await contract.Balances(buyer2.address)).to.equal((await contract.Predictions(11)).price);


    

  })

  

  





})