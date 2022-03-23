// contracts/Miner.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Base.sol";

abstract contract Miner is Base {
  function _setUpValidationRequest(uint256 _tokenId, uint256 _UID)
    internal
    validatorCountIncomplete(_UID)
    predictionEventNotStarted(_UID)
    newValidationRequest(_UID, _tokenId)
  {
    require(Predictions[_UID].state != State.Withdrawn, "Prediction Withdrawn");
    Predictions[_UID].validators[_tokenId].opening = ValidationStatus.Assigned;
    Predictions[_UID].validators[_tokenId].closing = ValidationStatus.Assigned;
    Predictions[_UID].validatorCount += 1;
    if (Predictions[_UID].validatorCount == MAX_VALIDATORS) {
      Predictions[_UID].status = Status.Complete;
    }
    OwnedValidations[msg.sender].push(
      ValidationData({tokenId: _tokenId, UID: _UID})
    );
    ActiveValidations[_UID][msg.sender] = true;
  }

  function _setUpOpeningVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    isNftOwner(_UID)
    returns (Vote storage)
  {
    require(
      Predictions[_UID].validators[_tokenId].opening ==
        ValidationStatus.Assigned,
      "Vote already cast!"
    );
    require(
      Predictions[_UID].startTime > block.timestamp,
      "Event already started"
    );
    return Predictions[_UID].validators[_tokenId];
  }

  function _setUpClosingVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    isNftOwner(_tokenId)
    returns (Vote storage)
  {
    require(
      Predictions[_UID].validators[_tokenId].miner == msg.sender,
      "Not assigned to miner"
    );
    require(
      Predictions[_UID].validators[_tokenId].closing ==
        ValidationStatus.Assigned,
      "Vote already cast!"
    );
    /**Cool down period is 6hrs (21600 secs) after the game ends */
    require(
      (block.timestamp > Predictions[_UID].endTime + SIX_HOURS &&
        block.timestamp < Predictions[_UID].endTime + TWELVE_HOURS),
      "Event not cooled down"
    );
    return Predictions[_UID].validators[_tokenId];
  }

  function _getWinningOpeningVote(uint256 _UID)
    internal
    view
    returns (ValidationStatus status)
  {
    if (
      Predictions[_UID].positiveOpeningVoteCount >
      Predictions[_UID].negativeOpeningVoteCount
    ) {
      return ValidationStatus.Positive;
    } else if (
      Predictions[_UID].positiveOpeningVoteCount <
      Predictions[_UID].negativeOpeningVoteCount
    ) {
      return ValidationStatus.Negative;
    } else {
      return ValidationStatus.Neutral;
    }
  }

  function _getWinningClosingVote(uint256 _UID)
    internal
    view
    returns (ValidationStatus status)
  {
    if (
      Predictions[_UID].positiveClosingVoteCount >
      Predictions[_UID].negativeClosingVoteCount
    ) {
      return ValidationStatus.Positive;
    } else if (
      Predictions[_UID].positiveClosingVoteCount <
      Predictions[_UID].negativeClosingVoteCount
    ) {
      return ValidationStatus.Negative;
    } else {
      return ValidationStatus.Neutral;
    }
  }

  function _refundMinerStakingFee(
    PredictionData storage _prediction,
    ValidationStatus _winningOpeningVote,
    ValidationStatus _winningClosingVote
  ) internal {
    for (uint256 index = 0; index < _prediction.votes.length; index++) {
      if (
        _prediction.votes[index].opening == _winningOpeningVote &&
        _prediction.votes[index].closing == _winningClosingVote
      ) {
        _prediction.votes[index].correctValidation = true;
        _prediction.votes[index].stakingFeeRefunded = true;
        Balances[_prediction.votes[index].miner] += minerStakingFee;
      } else {
        lockFunds(_prediction.votes[index].miner, minerStakingFee);
      }
    }
  }

  function _getMinerOpeningPredictionVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    returns (ValidationStatus)
  {
    return Predictions[_UID].validators[_tokenId].opening;
  }

  function _getMinerClosingPredictionVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    returns (ValidationStatus)
  {
    return Predictions[_UID].validators[_tokenId].closing;
  }

  function _returnNftAndStakingFee(uint256 _UID, uint256 _tokenId) internal {
    require(
      Predictions[_UID].validators[_tokenId].miner == msg.sender,
      "Not assigned to this miner"
    );
    require(
      !Predictions[_UID].validators[_tokenId].stakingFeeRefunded,
      "Staking fee already refunded"
    );
    Predictions[_UID].validators[_tokenId].stakingFeeRefunded = true;
    Balances[TokenOwner[_tokenId]] += minerStakingFee;
    _withdrawNFT(_tokenId);
  }

  function requestValidationWithWallet(
    uint256 _UID,
    uint256 _tokenId,
    bytes32 payload
  ) external virtual;

  function requestValidation(
    uint256 _UID,
    uint256 _tokenId,
    bytes32 payload
  ) external payable virtual;

  function submitOpeningVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _option
  ) external virtual;

  function updateMinerOpeningVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _vote
  ) external virtual;

  function submitClosingVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _option
  ) external virtual;

  function updateMinerClosingVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _vote
  ) external virtual;

  function withdrawMinerNftandStakingFee(uint256 _tokenId, uint256 _UID)
    external
    virtual;

  function inconclusiveMinerRefund(uint256 _UID, uint256 _tokenId)
    external
    virtual;

  function removeFromOwnedValidations(uint256[] calldata _UIDs)
    external
    virtual;
}
