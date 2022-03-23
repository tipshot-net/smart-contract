// contracts/Seller.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";

abstract contract Seller is Base {
  function _setupPrediction(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  )
    internal
    uniqueId(_UID)
    predictionMeetsMinimumRequirements(_startTime, _endTime)
  {
    Predictions[_UID].UID = _UID;
    Predictions[_UID].seller = msg.sender;
    Predictions[_UID].startTime = _startTime;
    Predictions[_UID].endTime = _endTime;
    Predictions[_UID].odd = _odd;
    Predictions[_UID].price = _price;

    OwnedPredictions[msg.sender].push(_UID);
    ActiveSoldPredictions[_UID][msg.sender] = true;
  }

  function _updateSellerProfile(
    PredictionData storage _prediction,
    bool _predictionWon
  ) internal {
    UserProfile[_prediction.seller].totalPredictions += 1;
    UserProfile[_prediction.seller].totalOdds += _prediction.odd;
    if (_predictionWon) {
      UserProfile[_prediction.seller].wonCount += 1;
      UserProfile[_prediction.seller].grossWinnings +=
        BANK_ROLL *
        _prediction.odd;
    } else {
      UserProfile[_prediction.seller].lostCount += 1;
    }
    _addToRecentPredictionsList(
      _prediction.seller,
      _prediction.odd,
      _predictionWon
    );
    uint256 _listLength = (UserProfile[_prediction.seller].last30Predictions)
      .length;
    (
      uint256 _wonCount,
      uint256 _grossWinnings,
      uint256 _moneyLost,
      uint256 _totalOdds
    ) = _getRecentPredictionsData(_prediction.seller);
    Performance[_prediction.seller].recentWinRate = _getRecentWinRate(
      _wonCount,
      _listLength
    );
    Performance[_prediction.seller].recentYield = _getRecentYield(
      _grossWinnings,
      _listLength
    );
    Performance[_prediction.seller].recentROI = _getRecentROI(
      _grossWinnings,
      _listLength
    );
    Performance[_prediction.seller]
      .recentProfitablity = _getRecentProfitability(
      _grossWinnings,
      _moneyLost,
      _listLength
    );
    Performance[_prediction.seller].recentAverageOdds = _getRecentAverageOdds(
      _totalOdds,
      _listLength
    );

    Performance[_prediction.seller].lifetimeWinRate = _getLifetimeWinRate(
      _prediction.seller
    );
    Performance[_prediction.seller].lifetimeYield = _getLifetimeYield(
      _prediction.seller
    );
    Performance[_prediction.seller].lifetimeROI = _getLifetimeROI(
      _prediction.seller
    );
    Performance[_prediction.seller]
      .lifetimeProfitability = _getLifetimeProfitability(_prediction.seller);
    Performance[_prediction.seller]
      .lifetimeAverageOdds = _getLifetimeAverageOdds(_prediction.seller);
  }

  function _refundSellerStakingFee(PredictionData storage _prediction)
    internal
  {
    if (
      _prediction.state != State.Denied && !_prediction.sellerStakingFeeRefunded
    ) {
      _prediction.sellerStakingFeeRefunded = true;
      Balances[_prediction.seller] += sellerStakingFee;
    }
  }

  function _setPredictionOutcome(PredictionData storage _prediction) internal {
    if (
      _prediction.positiveClosingVoteCount >
      _prediction.negativeClosingVoteCount
    ) {
      _prediction.status = Status.Won;
    } else if (
      _prediction.positiveClosingVoteCount <
      _prediction.negativeClosingVoteCount
    ) {
      _prediction.status = Status.Lost;
    } else {
      _prediction.status = Status.Inconclusive;
    }
  }

  function _setUpSellerClosing(
    PredictionData storage _prediction,
    bool _sellerVote
  ) internal onlySeller(_prediction.UID) {
    require(_prediction.state == State.Active, "Event no longer active");
    require(
      block.timestamp > _prediction.endTime + SIX_HOURS,
      "Event not cooled down"
    );
    _refundSellerStakingFee(_prediction);
    _setPredictionOutcome(_prediction);
    if (_prediction.status == Status.Inconclusive) {
      if (_sellerVote == true) {
        _prediction.positiveClosingVoteCount += 1;
      } else {
        _prediction.negativeClosingVoteCount += 1;
      }
      _setPredictionOutcome(_prediction);
    }
    _prediction.state = State.Concluded;
    bool _outcome = _prediction.status == Status.Won ? true : false;
    _updateSellerProfile(_prediction, _outcome);
  }

  function _getLifetimeWinRate(address _tipster)
    internal
    view
    returns (uint256)
  {
    return
      ((UserProfile[_tipster].wonCount * CONSTANT_VALUE_MULTIPLIER) /
        UserProfile[_tipster].totalPredictions) * TO_PERCENTAGE;
  }

  function _getLifetimeYield(address _tipster) internal view returns (int256) {
    int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
    int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
      int16(BANK_ROLL);

    return
      (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
        _capitalEmployed) * int8(TO_PERCENTAGE);
  }

  function _getLifetimeROI(address _tipster) internal view returns (int256) {
    int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
    int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
      int16(BANK_ROLL);

    return
      (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
        int16(BANK_ROLL)) * int8(TO_PERCENTAGE);
  }

  function _getLifetimeProfitability(address _tipster)
    internal
    view
    returns (int256)
  {
    int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
    int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
      int16(BANK_ROLL);
    int256 _moneyLost = int16(BANK_ROLL) *
      int256(UserProfile[_tipster].lostCount);

    return
      (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
        _moneyLost) * int8(TO_PERCENTAGE);
  }

  function _getLifetimeAverageOdds(address _tipster)
    internal
    view
    returns (uint256)
  {
    return
      (UserProfile[_tipster].totalOdds * CONSTANT_VALUE_MULTIPLIER) /
      UserProfile[_tipster].totalPredictions;
  }

  function _addToRecentPredictionsList(
    address _tipster,
    uint32 _odd,
    bool _won
  ) internal {
    PredictionHistory[] storage _list = UserProfile[_tipster].last30Predictions;
    uint256 _winnings = _won ? (uint256(BANK_ROLL) * _odd) : 0;
    if (_list.length < 30) {
      _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
    } else {
      for (uint256 i = 0; i < _list.length - 1; i++) {
        _list[i] = _list[i + 1];
      }
      _list.pop();
      _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
    }
  }

  function _getRecentWinRate(uint256 _wonCount, uint256 listLength)
    internal
    pure
    returns (uint256)
  {
    return
      ((_wonCount * CONSTANT_VALUE_MULTIPLIER) / listLength) * TO_PERCENTAGE;
  }

  function _getRecentYield(uint256 _grossWinnings, uint256 listLength)
    internal
    pure
    returns (int256)
  {
    uint256 _capitalEmployed = listLength * BANK_ROLL;
    return
      ((int256(_grossWinnings) - int256(_capitalEmployed)) *
        int16(CONSTANT_VALUE_MULTIPLIER)) /
      (int256(_capitalEmployed) * int8(TO_PERCENTAGE));
  }

  function _getRecentROI(uint256 _grossWinnings, uint256 listLength)
    internal
    pure
    returns (int256)
  {
    uint256 _capitalEmployed = listLength * BANK_ROLL;

    return
      (((int256(_grossWinnings) - int256(_capitalEmployed)) *
        int16(CONSTANT_VALUE_MULTIPLIER)) / int16(BANK_ROLL)) *
      int8(TO_PERCENTAGE);
  }

  function _getRecentProfitability(
    uint256 _grossWinnings,
    uint256 _moneyLost,
    uint256 listLength
  ) internal pure returns (int256) {
    uint256 _capitalEmployed = listLength * BANK_ROLL;

    return
      (((int256(_grossWinnings) - int256(_capitalEmployed)) *
        int16(CONSTANT_VALUE_MULTIPLIER)) / int256(_moneyLost)) *
      int8(TO_PERCENTAGE);
  }

  function _getRecentAverageOdds(uint256 _totalOdds, uint256 listLength)
    internal
    pure
    returns (uint256)
  {
    return (_totalOdds * CONSTANT_VALUE_MULTIPLIER) / listLength;
  }

  function _getRecentPredictionsData(address _tipster)
    internal
    view
    returns (
      uint256 _wonCount,
      uint256 _grossWinnings,
      uint256 _moneyLost,
      uint256 _totalOdds
    )
  {
    PredictionHistory[] memory _list = UserProfile[_tipster].last30Predictions;

    for (uint256 index = 0; index < _list.length; index++) {
      if (_list[index].winnings != 0) {
        _wonCount += 1;
      }
      _grossWinnings += _list[index].winnings;
      _moneyLost += _list[index].winnings == 0 ? BANK_ROLL : 0;
      _totalOdds += _list[index].odd;
    }
    return (_wonCount, _grossWinnings, _moneyLost, _totalOdds);
  }

  function createPredictionWithWallet(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external virtual;

  function createPrediction(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external payable virtual;

  function updatePrediction(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external virtual;

  function withdrawPrediction(uint256 _UID) external virtual;

  function refundSellerStakingFee(uint256 _UID) external virtual;

  function concludeTransaction(uint256 _UID, bool _sellerVote) external virtual;

  function removeFromOwnedPredictions(uint256[] calldata _UIDs)
    external
    virtual;
}
