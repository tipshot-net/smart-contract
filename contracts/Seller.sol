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

  // /@dev Calculate and updates sellers performance records
  // /@param _prediction Instance of the prediction data
  // /@param _predictionWon Outcome of the prediction (Win/Lose)

  // function _updateSellerProfile(
  //   PredictionData storage _prediction,
  //   bool _predictionWon
  // ) internal {
  //   UserProfile[_prediction.seller].totalPredictions += 1;
  //   UserProfile[_prediction.seller].totalOdds += _prediction.odd;
  //   if (_predictionWon) {
  //     UserProfile[_prediction.seller].wonCount += 1;
  //     UserProfile[_prediction.seller].grossWinnings +=
  //       BANK_ROLL *
  //       _prediction.odd;
  //   } else {
  //     UserProfile[_prediction.seller].lostCount += 1;
  //   }
  //   _addToRecentPredictionsList(
  //     _prediction.seller,
  //     _prediction.odd,
  //     _predictionWon
  //   );
  //   uint256 _listLength = (UserProfile[_prediction.seller].last30Predictions)
  //     .length;
  //   (
  //     uint256 _wonCount,
  //     uint256 _grossWinnings,
  //     uint256 _moneyLost,
  //     uint256 _totalOdds
  //   ) = _getRecentPredictionsData(_prediction.seller);
  //   Performance[_prediction.seller].recentWinRate = _getRecentWinRate(
  //     _wonCount,
  //     _listLength
  //   );
  //   Performance[_prediction.seller].recentYield = _getRecentYield(
  //     _grossWinnings,
  //     _listLength
  //   );
  //   Performance[_prediction.seller].recentROI = _getRecentROI(
  //     _grossWinnings,
  //     _listLength
  //   );
  //   Performance[_prediction.seller]
  //     .recentProfitablity = _getRecentProfitability(
  //     _grossWinnings,
  //     _moneyLost,
  //     _listLength
  //   );
  //   Performance[_prediction.seller].recentAverageOdds = _getRecentAverageOdds(
  //     _totalOdds,
  //     _listLength
  //   );

  //   Performance[_prediction.seller].lifetimeWinRate = _getLifetimeWinRate(
  //     _prediction.seller
  //   );
  //   Performance[_prediction.seller].lifetimeYield = _getLifetimeYield(
  //     _prediction.seller
  //   );
  //   Performance[_prediction.seller].lifetimeROI = _getLifetimeROI(
  //     _prediction.seller
  //   );
  //   Performance[_prediction.seller]
  //     .lifetimeProfitability = _getLifetimeProfitability(_prediction.seller);
  // }

  // ///@notice POV > 1  & POV < 3
  // ///@dev Refund seller staking fee -> prediction doesn't meet minimum POV (60%)
  // ///@param _prediction Instance of the prediction data

  function _refundSellerStakingFee(PredictionData storage _prediction)
    internal
  {
    if (
      _prediction.state != State.Rejected && !_prediction.sellerStakingFeeRefunded
    ) {
      _prediction.sellerStakingFeeRefunded = true;
      Balances[_prediction.seller] += sellerStakingFee;
    }
  }

  ///@dev Calculates rememant of mining fee (each miner received 1/5 of miningFee after successful validation)
  ///@param _UID Prediction ID
  ///@return remaining mining fee

  function remenantOfMiningFee(uint256 _UID) internal view returns (uint256) {
    uint256 miningFeePerValidator = miningFee / MAX_VALIDATORS;
    uint256 totalSpent = miningFeePerValidator *
      Predictions[_UID].validatorCount;
    return miningFee - totalSpent;
  }

  // ///@dev Sets Prediction outcome (Win/Loss)
  // ///@param _prediction Instance of the prediction data

  // // function _setPredictionOutcome(PredictionData storage _prediction) internal {
  // //   if (
  // //     _prediction.positiveClosingVoteCount >
  // //     _prediction.negativeClosingVoteCount
  // //   ) {
  // //     _prediction.status = Status.Won;
  // //   } else if (
  // //     _prediction.positiveClosingVoteCount <
  // //     _prediction.negativeClosingVoteCount
  // //   ) {
  // //     _prediction.status = Status.Lost;
  // //   } else {
  // //     _prediction.status = Status.Inconclusive;
  // //   }
  // // }

  // ///@dev Only the prediction seller can close the prediction to conclude the transaction
  // ///@param _prediction Instance of the prediction data
  // ///@param _sellerVote Only to be used if there's a tie between the PCV & NCV

  // // function _setUpSellerClosing(
  // //   PredictionData storage _prediction,
  // //   bool _sellerVote
  // // ) internal onlySeller(_prediction.UID) {
  // //   require(_prediction.state == State.Active, "Event no longer active");
  // //   require(
  // //     block.timestamp > _prediction.endTime + SIX_HOURS,
  // //     "Event not cooled down"
  // //   );
  // //   _refundSellerStakingFee(_prediction);
  // //   Balances[msg.sender] += remenantOfMiningFee(_prediction.UID); // refund remenant of mining fee
  // //   _setPredictionOutcome(_prediction);
  // //   if (_prediction.status == Status.Inconclusive) {
  // //     if (_sellerVote == true) {
  // //       _prediction.positiveClosingVoteCount += 1;
  // //     } else {
  // //       _prediction.negativeClosingVoteCount += 1;
  // //     }
  // //     _setPredictionOutcome(_prediction);
  // //   }
  // //   _prediction.state = State.Concluded;
  // //   bool _outcome = _prediction.status == Status.Won ? true : false;
  // //   _updateSellerProfile(_prediction, _outcome);
  // // }

  // ///@dev Calculate the percentage winrate based on sellers entire prediction sale history
  // ///@param _tipster Address of seller -> tipster
  // ///@return Winrate (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getLifetimeWinRate(address _tipster)
  //   private
  //   view
  //   returns (uint256)
  // {
  //   return
  //     ((UserProfile[_tipster].wonCount * CONSTANT_VALUE_MULTIPLIER) /
  //       UserProfile[_tipster].totalPredictions) * TO_PERCENTAGE;
  // }

  // ///@dev Calculate the lifetime yield based on sellers entire prediction sale history
  // ///@param _tipster Address of seller -> tipster
  // ///@return Yield (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getLifetimeYield(address _tipster) private view returns (int256) {
  //   int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
  //   int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
  //     int16(BANK_ROLL);

  //   return
  //     (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
  //       _capitalEmployed) * int8(TO_PERCENTAGE);
  // }

  // ///@dev Calculate the lifetime ROI based on sellers entire prediction sale history
  // ///@param _tipster Address of seller -> tipster
  // ///@return Lifetime ROI (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getLifetimeROI(address _tipster) private view returns (int256) {
  //   int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
  //   int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
  //     int16(BANK_ROLL);

  //   return
  //     (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
  //       int16(BANK_ROLL)) * int8(TO_PERCENTAGE);
  // }

  // ///@dev Calculate the lifetime Profitability based on sellers entire prediction sale history
  // ///@param _tipster Address of seller -> tipster
  // ///@return Lifetime profitability (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getLifetimeProfitability(address _tipster)
  //   private
  //   view
  //   returns (int256)
  // {
  //   int256 _grossWinings = int256(UserProfile[_tipster].grossWinnings);
  //   int256 _capitalEmployed = int256(UserProfile[_tipster].totalPredictions) *
  //     int16(BANK_ROLL);
  //   int256 _moneyLost = int16(BANK_ROLL) *
  //     int256(UserProfile[_tipster].lostCount);

  //   return
  //     (((_grossWinings - _capitalEmployed) * int16(CONSTANT_VALUE_MULTIPLIER)) /
  //       _moneyLost) * int8(TO_PERCENTAGE);
  // }

  // ///@dev Calculate the lifetime average odds based on sellers entire prediction sale history
  // ///@param _tipster Address of seller -> tipster
  // ///@return Lifetime average odds (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // ///@dev Updates the array-list of the tipster last 30 predictions data
  // ///@param _tipster Address of seller -> tipster
  // ///@param _odd Odd of prediction
  // ///@param _won Outcome of prediction (Win/Loss)

  // function _addToRecentPredictionsList(
  //   address _tipster,
  //   uint32 _odd,
  //   bool _won
  // ) private {
  //   PredictionHistory[] storage _list = UserProfile[_tipster].last30Predictions;
  //   uint256 _winnings = _won ? (uint256(BANK_ROLL) * _odd) : 0;
  //   if (_list.length < 30) {
  //     _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
  //   } else {
  //     for (uint256 i = 0; i < _list.length - 1; i++) {
  //       _list[i] = _list[i + 1];
  //     }
  //     _list.pop();
  //     _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
  //   }
  // }

  // ///@dev Calculate the tipster percentage winrate based on last 30 predictions data
  // ///@param _wonCount Total wins in the last 30 concluded predictions
  // ///@param _listLength Size of recent predictions array (max => 30)
  // ///@return Recent winrate (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getRecentWinRate(uint256 _wonCount, uint256 _listLength)
  //   private
  //   pure
  //   returns (uint256)
  // {
  //   return
  //     ((_wonCount * CONSTANT_VALUE_MULTIPLIER) / _listLength) * TO_PERCENTAGE;
  // }

  // ///@dev Calculate the tipster recent yield based on last 30 predictions data
  // ///@param _grossWinnings Total winnings (based on capital employed) of recent predictions
  // ///@param _listLength Size of recent predictions array (max => 30)
  // ///@return Recent yield (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getRecentYield(uint256 _grossWinnings, uint256 _listLength)
  //   private
  //   pure
  //   returns (int256)
  // {
  //   uint256 _capitalEmployed = _listLength * BANK_ROLL;
  //   return
  //     ((int256(_grossWinnings) - int256(_capitalEmployed)) *
  //       int16(CONSTANT_VALUE_MULTIPLIER)) /
  //     (int256(_capitalEmployed) * int8(TO_PERCENTAGE));
  // }

  // ///@dev Calculate the tipster recent ROI based on last 30 predictions data
  // ///@param _grossWinnings Total winnings (based on capital employed) of recent predictions
  // ///@param _listLength Size of recent predictions array (max => 30)
  // ///@return Recent ROI (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getRecentROI(uint256 _grossWinnings, uint256 _listLength)
  //   private
  //   pure
  //   returns (int256)
  // {
  //   uint256 _capitalEmployed = _listLength * BANK_ROLL;

  //   return
  //     (((int256(_grossWinnings) - int256(_capitalEmployed)) *
  //       int16(CONSTANT_VALUE_MULTIPLIER)) / int16(BANK_ROLL)) *
  //     int8(TO_PERCENTAGE);
  // }

  // ///@dev Calculate the tipster recent profitability based on last 30 predictions data
  // ///@param _grossWinnings Total winnings (based on capital employed) of recent predictions
  // ///@param _moneyLost Total losses of recent predictions
  // ///@param _listLength Size of recent predictions array (max => 30)
  // ///@return Recent profitability (between 0 - 100%) -> multiplied by 1000 to preserve floating point numbers

  // function _getRecentProfitability(
  //   uint256 _grossWinnings,
  //   uint256 _moneyLost,
  //   uint256 _listLength
  // ) private pure returns (int256) {
  //   uint256 _capitalEmployed = _listLength * BANK_ROLL;

  //   return
  //     (((int256(_grossWinnings) - int256(_capitalEmployed)) *
  //       int16(CONSTANT_VALUE_MULTIPLIER)) / int256(_moneyLost)) *
  //     int8(TO_PERCENTAGE);
  // }

  // ///@dev Calculate the tipster recent average odds based on last 30 predictions data
  // ///@param _totalOdds Total odds of recent predictions
  // ///@param _listLength Size of recent predictions array (max => 30)
  // ///@return Recent odds -> multiplied by 1000 to preserve floating point numbers

  // function _getRecentAverageOdds(uint256 _totalOdds, uint256 _listLength)
  //   private
  //   pure
  //   returns (uint256)
  // {
  //   return (_totalOdds * CONSTANT_VALUE_MULTIPLIER) / _listLength;
  // }

  // ///@dev Retrieve tipster recent predictions data (max => 30)
  // ///@param _tipster Address of seller -> tipster
  // ///@return _wonCount _grossWinnings _moneyLost _totalOdds

  // function _getRecentPredictionsData(address _tipster)
  //   private
  //   view
  //   returns (
  //     uint256 _wonCount,
  //     uint256 _grossWinnings,
  //     uint256 _moneyLost,
  //     uint256 _totalOdds
  //   )
  // {
  //   PredictionHistory[] memory _list = UserProfile[_tipster].last30Predictions;

  //   for (uint256 index = 0; index < _list.length; index++) {
  //     if (_list[index].winnings != 0) {
  //       _wonCount += 1;
  //     }
  //     _grossWinnings += _list[index].winnings;
  //     _moneyLost += _list[index].winnings == 0 ? BANK_ROLL : 0;
  //     _totalOdds += _list[index].odd;
  //   }
  //   return (_wonCount, _grossWinnings, _moneyLost, _totalOdds);
  // }


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

  // function refundSellerStakingFee(uint256 _UID) external virtual;

  // // function concludeTransaction(uint256 _UID, bool _sellerVote) external virtual;

  // function removeFromOwnedPredictions(uint256[] calldata _UIDs)
  //   external
  //   virtual;
}
