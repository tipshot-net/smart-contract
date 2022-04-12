// contracts/AttackerContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Predictsea.sol";

contract AttackerContract {
  // uint256 public balanceOfContract;
  // Predictsea public _predictsea;
  // uint256 public UID;
  // uint256 public stakingFee;
  // bool public withdrawFail;
  // function setUpContract(address payable _predictseaContract) external {
  //   _predictsea = Predictsea(_predictseaContract);
  // }
  // // function createPrediction(
  // //   uint256 _UID,
  // //   uint256 _startTime,
  // //   uint256 _endTime,
  // //   uint16 _odd,
  // //   uint256 _price
  // // ) external {
  // //   _predictsea.createPrediction{value: stakingFee}(
  // //     _UID,
  // //     _startTime,
  // //     _endTime,
  // //     _odd,
  // //     _price
  // //   );
  // //   balanceOfContract -= stakingFee;
  // // }
  // function withdraw() public {
  //   _predictsea.withdrawPrediction(UID);
  // }
  // function deposit() external payable {
  //   balanceOfContract += msg.value;
  // }
  // function withdrawFailed() external payable {
  //   withdrawFail = true;
  //   _predictsea.withdrawFunds(stakingFee);
  // }
  // receive() external payable {
  //   balanceOfContract += msg.value;
  //   if (!withdrawFail) {
  //     withdraw(); //attempt to withdraw again
  //   }
  // }
}
