// contracts/Buyer.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Base.sol";

abstract contract Buyer is Base {
  

  // /// @dev Refunds prediction purchase fee back to buyers wallet.
  // /// @param _UID prediction ID

  // function _returnBuyerPurchaseFee(uint256 _UID) internal {
  //   require(
  //     Predictions[_UID].buyers[msg.sender].purchased,
  //     "Purchase not found"
  //   );

  //   require(
  //     !Predictions[_UID].buyers[msg.sender].refunded,
  //     "Purchase fee already refunded"
  //   );

  //   Predictions[_UID].buyers[msg.sender].refunded = true;

  //   Balances[msg.sender] += Predictions[_UID].price;
  // }

  // function purchasePredictionWithWallet(uint256 _UID, string calldata email)
  //   external
  //   virtual;

  function purchasePrediction(uint256 _UID, string memory _key)
    external
    payable
    virtual;

  // function buyerRefund(uint256 _UID) external virtual;

  // function inconclusiveBuyerRefund(uint256 _UID) external virtual;

  // function removeFromBoughtPredictions(uint256[] calldata _UIDs)
  //   external
  //   virtual;
}
