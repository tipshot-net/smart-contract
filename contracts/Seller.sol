// contracts/Seller.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";


abstract contract Seller is Base {
    
  /// @dev Sets up parameters applicable to wallet and direct-payment prediction upload
  /// @param _id generated prediction id
  /// @param _ipfsHash ipfs Url hash containing the encrypted prediction data
  /// @param _key prediction data encryption key (encrypted)
  /// @param _startTime Timestamp of the kickoff time of the first prediction event
  /// @param _endTime Timestamp of the proposed end of the last prediction event
  /// @param _odd Total prediction odd (multipled by 100 -> to keep in whole number format)
  /// @param _price Selling price of prediction in wei
  

  function _setupPrediction(
    uint256 _id,
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  )
    internal
    predictionMeetsMinimumRequirements(_startTime, _endTime)
  {
   
    Predictions[_id].seller = msg.sender;
    Predictions[_id].ipfsHash = _ipfsHash;
    Predictions[_id].key = _key;
    Predictions[_id].createdAt = block.timestamp;
    Predictions[_id].startTime = _startTime;
    Predictions[_id].endTime = _endTime;
    Predictions[_id].odd = _odd;
    Predictions[_id].price = _price;

  }

 
  function createPrediction(
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external payable virtual;

  function updatePrediction(
    uint256 _id,
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external virtual;

  function withdrawPrediction(uint256 _UID) external virtual;

  // // function concludeTransaction(uint256 _UID, bool _sellerVote) external virtual;

  // function removeFromOwnedPredictions(uint256[] calldata _UIDs)
  //   external
  //   virtual;
}
