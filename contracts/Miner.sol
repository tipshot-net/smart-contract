// contracts/Miner.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Base.sol";

abstract contract Miner is Base {
  ///@dev Miners use thier NFT (_tokenId) to request to validate a prediction (_UID)
  ///@param _tokenId NFT token id
  ///@param _UID ID of requested prediction

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

  /*╔══════════════════════════════╗
     ║  TRANSFER NFT TO CONTRACT    ║
     ╚══════════════════════════════╝*/

  function _transferNftToContract(uint256 _tokenId) internal {
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
        "Seller doesn't own NFT"
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

  ///@dev Checks if all requirements for a miner to cast opening vote on prediction are satisfied
  ///@param _tokenId NFT token id
  ///@param _UID ID of requested prediction
  ///@return _vote -> miners opening vote details

  function _setUpOpeningVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    isNftOwner(_UID)
    returns (Vote storage _vote)
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

  ///@dev Checks if all requirements for a miner to cast closing vote on prediction are satisfied
  ///@param _tokenId NFT token id
  ///@param _UID ID of requested prediction
  ///@return _vote -> miners closing vote details

  function _setUpClosingVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    isNftOwner(_tokenId)
    returns (Vote storage _vote)
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

  ///@dev Calculate majority opening vote
  ///@param _UID Prediction ID
  ///@return status -> majority opening consensus

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

  ///@dev Calculate majority closing vote
  ///@param _UID Prediction ID
  ///@return status -> majority closing consensus

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

  ///@dev Refund miner staking fee based on the conditions that the opening and
  ///closing vote matches majority consensus, else lock staking fee
  ///@param _prediction Predicition data
  ///@param _winningOpeningVote majority prediction opening vote consensus
  ///@param _winningClosingVote majority prediction closing vote consensus

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

  ///@dev View function to get the a miner's opening vote for a particular prediction
  ///@param _UID Prediction ID
  ///@param _tokenId NFT token ID
  ///@return _openingVote -> miner's prediction opening vote

  function _getMinerOpeningPredictionVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    returns (ValidationStatus _openingVote)
  {
    return Predictions[_UID].validators[_tokenId].opening;
  }

  ///@dev View function to get the a miner's closing vote for a particular prediction
  ///@param _UID Prediction ID
  ///@param _tokenId NFT token ID
  ///@return _closingVote -> miner's prediction closing vote

  function _getMinerClosingPredictionVote(uint256 _UID, uint256 _tokenId)
    internal
    view
    returns (ValidationStatus _closingVote)
  {
    return Predictions[_UID].validators[_tokenId].closing;
  }

  ///@dev Return NFT and staking fee to miner
  ///@param _UID Prediction ID
  ///@param _tokenId NFT token ID

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

  ///@dev Lock some amount of wei in the contract, to be released in a future date
  ///@param _user Owner of locked funds
  ///@param _amount Amount to be locked (in wei)

  function lockFunds(address _user, uint256 _amount)
    internal
    notZeroAddress(_user)
  {
    LockedFunds[_user].amount += _amount;
    LockedFunds[_user].lastPushDate += block.timestamp;
    LockedFunds[_user].releaseDate += (TWENTY_FOUR_HOURS * 30);
    LockedFunds[_user].totalInstances += 1;
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
