// contracts/Miner.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "hardhat/console.sol";
import "./Base.sol";

abstract contract Miner is Base {
 

  uint256 private pointer;

  function _assignPredictionToMiner(uint256 _tokenId, string memory _key) internal returns(uint256) {
    uint256 current = pointer + 1;
  
    //if prediction withdrawn or prediction first game starting in less than 2 hours => skip;
    if(miningPool[pointer] == 0 || ((block.timestamp + (2 * HOURS)) > Predictions[current].startTime )){
      pointer = next(pointer);
      current = pointer + 1;
    }
   
    require(pointer < miningPool.length, "Mining pool currently empty");
    require(block.timestamp >= (Predictions[current].createdAt + (4 * HOURS)), "Not available for mining");
    Validations[_tokenId][current].assigned = true;
    PredictionStats[current].validatorCount += 1;
    OwnedValidations[msg.sender].push(
      ValidationData({ id: current, tokenId: _tokenId, key: _key})
    );
    uint256 _id = current;
    if(PredictionStats[current].validatorCount == MAX_VALIDATORS){
      delete miningPool[pointer];
      pointer += 1;
    }

    return _id;
  }

  function next(uint256 point) internal view returns(uint256) {
    uint x = point + 1;
    while(x < miningPool.length){
      if(miningPool[x] != 0){
        break;
      }
      x += 1;
    }
    return x;
  }

  /*╔══════════════════════════════╗
     ║  TRANSFER NFT TO CONTRACT    ║
     ╚══════════════════════════════╝*/

  function _transferNftToContract(uint256 _tokenId) internal notZeroAddress(NFT_CONTRACT_ADDRESS) {
    if (IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender) {
      IERC721(NFT_CONTRACT_ADDRESS).safeTransferFrom(
        msg.sender,
        address(this),
        _tokenId
      );
      require(
        IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == address(this),
        "nft transfer failed"
      );
    } else {
      require(
        IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == address(this),
        "Doesn't own NFT"
      );
    }

    TokenOwner[_tokenId] = msg.sender;
  }

  /*╔════════════════════════════════════╗
    ║ RETURN NFT FROM CONTRACT TO OWNER  ║
    ╚════════════════════════════════════╝*/

  function _withdrawNFT(uint256 _tokenId)
    internal
    isNftOwner(_tokenId)
    notZeroAddress(TokenOwner[_tokenId])
     notZeroAddress(NFT_CONTRACT_ADDRESS)
  {
    address _nftRecipient = TokenOwner[_tokenId];
    IERC721(NFT_CONTRACT_ADDRESS).safeTransferFrom(
      address(this),
      _nftRecipient,
      _tokenId
    );
    require(
      IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender,
      "nft transfer failed"
    );
    TokenOwner[_tokenId] = address(0);
  }

  function addToActivePool(uint256 _id) internal {
    activePool.push(_id);
    Index[_id] = activePool.length - 1;
  }


  
  // /@dev Calculate majority opening vote
  // /@param _UID Prediction ID
  // /@return status -> majority opening consensus

  // function _getWinningOpeningVote(uint256 _UID)
  //   internal
  //   view
  //   returns (ValidationStatus status)
  // {
  //   if (
  //     Predictions[_UID].positiveOpeningVoteCount >
  //     Predictions[_UID].negativeOpeningVoteCount
  //   ) {
  //     return ValidationStatus.Positive;
  //   } else if (
  //     Predictions[_UID].positiveOpeningVoteCount <
  //     Predictions[_UID].negativeOpeningVoteCount
  //   ) {
  //     return ValidationStatus.Negative;
  //   } else {
  //     return ValidationStatus.Neutral;
  //   }
  // }

  // /@dev Calculate majority closing vote
  // /@param _UID Prediction ID
  // /@return status -> majority closing consensus

  // function _getWinningClosingVote(uint256 _UID)
  //   internal
  //   view
  //   returns (ValidationStatus status)
  // {
  //   if (
  //     Predictions[_UID].positiveClosingVoteCount >
  //     Predictions[_UID].negativeClosingVoteCount
  //   ) {
  //     return ValidationStatus.Positive;
  //   } else if (
  //     Predictions[_UID].positiveClosingVoteCount <
  //     Predictions[_UID].negativeClosingVoteCount
  //   ) {
  //     return ValidationStatus.Negative;
  //   } else {
  //     return ValidationStatus.Neutral;
  //   }
  // }

  // /@dev Refund miner staking fee based on the conditions that the opening and
  // /closing vote matches majority consensus, else lock staking fee
  // /@param _prediction Predicition data
  // /@param _winningOpeningVote majority prediction opening vote consensus
  // /@param _winningClosingVote majority prediction closing vote consensus

  // function _refundMinerStakingFee(
  //   PredictionData storage _prediction,
  //   ValidationStatus _winningOpeningVote,
  //   ValidationStatus _winningClosingVote
  // ) internal {
    // for (uint256 index = 0; index < _prediction.votes.length; index++) {
    //   if (
    //     _prediction.votes[index].opening == _winningOpeningVote &&
    //     _prediction.votes[index].closing == _winningClosingVote
    //   ) {
    //     _prediction.votes[index].correctValidation = true;
    //     _prediction.votes[index].stakingFeeRefunded = true;
    //     Balances[_prediction.votes[index].miner] += minerStakingFee;
    //   } else {
    //     lockFunds(_prediction.votes[index].miner, minerStakingFee);
    //   }
    // }
  //}

  // /@dev View function to get the a miner's opening vote for a particular prediction
  // /@param _UID Prediction ID
  // /@param _tokenId NFT token ID
  // /@return _openingVote -> miner's prediction opening vote

  // function _getMinerOpeningPredictionVote(uint256 _UID, uint256 _tokenId)
  //   internal
  //   view
  //   returns (ValidationStatus _openingVote)
  // {
  //   return Predictions[_UID].validators[_tokenId].opening;
  // }

  // ///@dev View function to get the a miner's closing vote for a particular prediction
  // ///@param _UID Prediction ID
  // ///@param _tokenId NFT token ID
  // ///@return _closingVote -> miner's prediction closing vote

  // function _getMinerClosingPredictionVote(uint256 _UID, uint256 _tokenId)
  //   internal
  //   view
  //   returns (ValidationStatus _closingVote)
  // {
  //   return Predictions[_UID].validators[_tokenId].closing;
  // }

  // ///@dev Return NFT and staking fee to miner
  // ///@param _UID Prediction ID
  // ///@param _tokenId NFT token ID

  // function _returnNftAndStakingFee(uint256 _UID, uint256 _tokenId) internal {
  //   // require(
  //   //   Predictions[_UID].validators[_tokenId].miner == msg.sender,
  //   //   "Not assigned to this miner"
  //   // );
  //   // require(
  //   //   !Predictions[_UID].validators[_tokenId].stakingFeeRefunded,
  //   //   "Staking fee already refunded"
  //   // );
  //   // Predictions[_UID].validators[_tokenId].stakingFeeRefunded = true;
  //   // Balances[TokenOwner[_tokenId]] += minerStakingFee;
  //   // _withdrawNFT(_tokenId);
  // }

  // ///@dev Lock some amount of wei in the contract, to be released in a future date
  // ///@param _user Owner of locked funds
  // ///@param _amount Amount to be locked (in wei)

  // function lockFunds(address _user, uint256 _amount)
  //   internal
  //   notZeroAddress(_user)
  // {
  //   LockedFunds[_user].amount += _amount;
  //   LockedFunds[_user].lastPushDate += block.timestamp;
  //   LockedFunds[_user].releaseDate += (TWENTY_FOUR_HOURS * 30);
  //   LockedFunds[_user].totalInstances += 1;
  // }

  function requestValidation(
    uint256 _tokenId,
    string memory _key
  ) external payable virtual;

  function submitOpeningVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  ) external virtual;


  function submitClosingVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  ) external virtual;

  // // function updateMinerClosingVote(
  // //   uint256 _UID,
  // //   uint256 _tokenId,
  // //   uint8 _vote
  // // ) external virtual;

  // function withdrawMinerNftandStakingFee(uint256 _tokenId, uint256 _UID)
  //   external
  //   virtual;

  // function inconclusiveMinerRefund(uint256 _UID, uint256 _tokenId)
  //   external
  //   virtual;

  // function removeFromOwnedValidations(uint256[] calldata _UIDs)
  //   external
  //   virtual;
}
