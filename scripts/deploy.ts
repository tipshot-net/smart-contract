import { ethers } from "hardhat"

async function main() {
  const [deployer] = await ethers.getSigners()

  console.log("Deploying contracts with the account:", deployer.address)

  console.log("Account balance:", (await deployer.getBalance()).toString())

  const Tipshot = await ethers.getContractFactory("Tipshot")
  const MinerNFT = await ethers.getContractFactory("MinerNFT")

  const tipshot = await Tipshot.deploy()
  const minerNFT = await MinerNFT.deploy("", "", "")

  //verify: npx hardhat verify --network polygon-mainnet DEPLOYED_CONTRACT_ADDRESS
  console.log("Tipshot address:", tipshot.address)
  //verify: npx hardhat verify --network polygon-mainnet --constructor-args minerNFTArgs.ts DEPLOYED_CONTRACT_ADDRESS
  console.log("Miners Token address:", minerNFT.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
