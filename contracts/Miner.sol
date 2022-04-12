// contracts/Miner.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "hardhat/console.sol";
import "./Base.sol";

abstract contract Miner is Base {
  uint256 private pointer;

  function _assignPredictionToMiner(uint256 _tokenId, string memory _key)
    internal
    returns (uint256)
  {
    uint256 current = pointer + 1;

    //if prediction withdrawn or prediction first game starting in less than 2 hours => skip;
    if (
      miningPool[pointer] == 0 ||
      ((block.timestamp + (2 * HOURS)) > Predictions[current].startTime)
    ) {
      pointer = next(pointer);
      current = pointer + 1;
    }

    require(pointer < miningPool.length, "Mining pool currently empty");
    require(
      block.timestamp >= (Predictions[current].createdAt + (4 * HOURS)),
      "Not available for mining"
    );
    Validations[_tokenId][current].assigned = true;
    PredictionStats[current].validatorCount += 1;
    OwnedValidations[msg.sender].push(
      ValidationData({id: current, tokenId: _tokenId, key: _key})
    );
    uint256 _id = current;
    if (PredictionStats[current].validatorCount == MAX_VALIDATORS) {
      delete miningPool[pointer];
      pointer += 1;
    }

    return _id;
  }

  function next(uint256 point) internal view returns (uint256) {
    uint256 x = point + 1;
    while (x < miningPool.length) {
      if (miningPool[x] != 0) {
        break;
      }
      x += 1;
    }
    return x;
  }

  /*╔══════════════════════════════╗
     ║  TRANSFER NFT TO CONTRACT    ║
     ╚══════════════════════════════╝*/

  function _transferNftToContract(uint256 _tokenId)
    internal
    notZeroAddress(NFT_CONTRACT_ADDRESS)
  {
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

  function addToRecentPredictionsList(address seller, uint256 _id) internal {
    if (User[seller].spot == 30) {
      User[seller].spot == 0;
    }
    uint8 _spot = User[seller].spot;
    User[seller].last30Predictions[_spot] = _id;
    User[seller].spot += 1;
  }

  function removeFromActivePool(uint256 _id) internal {
    uint256 _index = Index[_id];
    activePool[_index] = activePool[activePool.length - 1];
    Index[activePool[_index]] = _index;
    activePool.pop();
  }

  ///@dev Calculate majority opening vote
  ///@param _id Prediction ID
  ///@return status -> majority opening consensus

  function _getWinningOpeningVote(uint256 _id)
    internal
    view
    returns (ValidationStatus status)
  {
    if (PredictionStats[_id].upvoteCount > PredictionStats[_id].downvoteCount) {
      return ValidationStatus.Positive;
    } else {
      return ValidationStatus.Negative;
    }
  }

  ///@dev Calculate majority closing vote
  ///@param _id Prediction ID
  ///@return status -> majority closing consensus

  function _getWinningClosingVote(uint256 _id)
    internal
    view
    returns (ValidationStatus status)
  {
    if (
      PredictionStats[_id].wonVoteCount > PredictionStats[_id].lostVoteCount
    ) {
      return ValidationStatus.Positive;
    } else {
      return ValidationStatus.Negative;
    }
  }

  function _refundMinerStakingFee(uint256 _id, uint256 _tokenId)
    internal
    returns (bool)
  {
    Vote memory _vote = Validations[_tokenId][_id];
    PredictionData memory _prediction = Predictions[_id];
    bool refund = false;
    if (
      _vote.opening == _prediction.winningOpeningVote &&
      _vote.closing == _prediction.winningClosingVote
    ) {
      Balances[_vote.miner] += minerStakingFee;
      refund = true;
    } else {
      lockFunds(_vote.miner, minerStakingFee);
    }
    return refund;
  }

  function lockFunds(address _user, uint256 _amount)
    internal
    notZeroAddress(_user)
  {
    LockedFunds[_user].amount += _amount;
    LockedFunds[_user].lastPushDate += block.timestamp;
    LockedFunds[_user].releaseDate += (24 * HOURS * 30);
    LockedFunds[_user].totalInstances += 1;
  }

  function requestValidation(uint256 _tokenId, string memory _key)
    external
    payable
    virtual;

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

  function withdrawMinerNftandStakingFee(uint256 _id, uint256 _tokenId)
    external
    virtual;

  function settleMiner(uint256 _id, uint256 _tokenId) external virtual;

  // function removeFromOwnedValidations(uint256[] calldata _UIDs)
  //   external
  //   virtual;
}
