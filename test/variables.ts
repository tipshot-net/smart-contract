import { ethers } from "hardhat";

export default {
miningFee: ethers.utils.parseEther("10.0"),
sellerStakingFee: ethers.utils.parseEther("40.0"),
minerStakingFee: ethers.utils.parseEther("10.0"),
minerPercentage: 5
}