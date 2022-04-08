// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";
import "./Seller.sol";
import "./Miner.sol";
import "./Buyer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title PredictSea {Blockchain powered sport prediction marketplace}

contract Predictsea is IERC721Receiver, Seller, Miner, Buyer {

  using Counters for Counters.Counter;

  Counters.Counter private _predictionIds;
  
  /*╔═════════════════════════════╗
    ║           EVENTS            ║
    ╚═════════════════════════════╝*/

  event VariableUpdated(
    uint256 miningFee,
    uint256 minerStakingFee,
    uint32 minerPercentage
  );
  event PredictionCreated(
    address indexed sender,
    uint256 indexed id,
    string ipfsHash,
    string key
  );
  event PredictionUpdated(
    address indexed sender,
    uint256 indexed id,
    string ipfsHash,
    string key
  );
  event DepositCreated(address sender, uint256 value);

  event ValidationAssigned(
    address miner,
    uint256 indexed id,
    uint256 indexed tokenId
  );
  event OpeningVoteSubmitted(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint8 option,
    State state
  );
  event PredictionPurchased(uint256 indexed UID, address buyer, string email);
  event ClosingVoteSubmitted(
    uint256 indexed UID,
    uint256 indexed tokenId,
    uint8 option
  );
  event TransactionConcluded(uint256 indexed UID, Status status);
  event PredictionWithdrawn(uint256 indexed UID, address seller);
  
  event MinerOpeningVoteUpdated(
    uint256 indexed UID,
    uint256 indexed tokenId,
    uint8 vote
  );
  event MinerClosingVoteUpdated(
    uint256 indexed UID,
    uint256 indexed tokenId,
    uint8 vote
  );
  event Withdrawal(address indexed recipient, uint256 amount, uint256 balance);
  event UsernameCreated(address indexed user, bytes32 username);
  event MinerNFTAndStakingFeeWithdrawn(
    uint256 indexed UID,
    uint256 indexed tokenId,
    address indexed seller
  );
  event SellerStakingFeeRefunded(uint256 indexed UID, address indexed seller);
  event LockedFundsTransferred(
    address indexed user,
    uint256 amount,
    uint256 lockedBalance
  );
  event PurchaseRefunded(uint256 indexed UID, address indexed buyer);

  /*╔═════════════════════════════╗
    ║             END             ║
    ║            EVENTS           ║
    ╚═════════════════════════════╝*/

  // constructor
  constructor() {
    owner = payable(msg.sender);
  }

  ///@dev Set all variables in one function to reduce contract size
  ///@param _miningFee miner staking fee in wei (paid by prediction seller, distributed among miners)
  ///@param _minerStakingFee Miner staking fee in wei
  ///@param _minerPercentage Percentage of the total_prediction_earnings each miner receives in event of winning (Value between 0 - 100)

  function setVariables(
    uint256 _miningFee,
    uint256 _minerStakingFee,
    uint32 _minerPercentage
  ) external onlyOwner {
    miningFee = _miningFee;
    minerStakingFee = _minerStakingFee;
    minerPercentage = _minerPercentage;
    emit VariableUpdated(
      miningFee,
      minerStakingFee,
      minerPercentage
    );
  }

  ///@dev Allows owner to set NFT address
  ///@param _NftAddress Deployed NFT contract address

  function setNftAddress(address _NftAddress) external onlyOwner notZeroAddress(_NftAddress) {
    NFT_CONTRACT_ADDRESS = _NftAddress;
  }

  ///@dev creates new prediction added to the mining pool
  ///@param _ipfsHash ipfs Url hash containing the encrypted prediction data
  ///@param _key prediction data encryption key (encrypted)
  ///@param _startTime expected start time of the first game in the predictions
  ///@param _endTime expected end time of the last game in the predictions
  ///@param _odd total accumulated odd
  ///@param _price selling price

  function createPrediction(
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external payable override {
    if(msg.value < miningFee){
      require(Balances[msg.sender] >= (miningFee - msg.value), "Insufficient balance");
      Balances[msg.sender] -= (miningFee - msg.value);
    }else{
      uint256 bal = msg.value - miningFee;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    _predictionIds.increment();
    uint256 _id = _predictionIds.current();

    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    miningPool.push(_id);

    OwnedPredictions[msg.sender].push(_id);

    emit PredictionCreated(
      msg.sender,
      _id,
      _ipfsHash,
      _key
    );
  }

  ///@notice Seller can withdraw prediction only before any miner has mined it.
  ///@param _id prediction Id

  function withdrawPrediction(uint256 _id)
    external
    override
    onlySeller(_id)
    notMined(_id)
  {
    require(
      PredictionStats[_id].state != State.Withdrawn,
      "Prediction already withdrawn!"
    );
    PredictionStats[_id].state = State.Withdrawn;
    delete miningPool[_id - 1]; //delete prediction entry from mining pool
    Balances[Predictions[_id].seller] += miningFee; //Refund mining fee
    emit PredictionWithdrawn(_id, msg.sender);
  }

  ///@notice Prediction info can only be updated only before any miner has mined it.
  function updatePrediction(
    uint256 _id,
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external override onlySeller(_id) notMined(_id) {
    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    emit PredictionUpdated(
       msg.sender,
      _id,
     _ipfsHash,
     _key
    );
  }

  ///@dev miner can place validation request and pay staking fee by sending it in the transaction
  ///@param _tokenId NFT token Id
  ///@param _key encrypted purchase key
  
  function requestValidation(
    uint256 _tokenId,
    string memory _key
  ) external payable override {
    if(msg.value < minerStakingFee){
      require(Balances[msg.sender] >= (minerStakingFee - msg.value), "Insufficient balance");
      Balances[msg.sender] -= (minerStakingFee - msg.value);
    }else{
      uint256 bal = msg.value - minerStakingFee;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    require(miningPool.length > 0, "mining pool empty");

    _transferNftToContract(_tokenId);
    uint256 _id = _assignPredictionToMiner(_tokenId, _key);
    emit ValidationAssigned(msg.sender, _id, _tokenId);
  }

  ///@dev miner submits opening validation decision on seller's prediction
  ///@param _id Prediction ID
  ///@param _tokenId Miner's NFT token Id
  ///@param _option Miner's validation decision

  function submitOpeningVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  ) external override predictionEventNotStarted(_id) isNftOwner(_tokenId) {
    require(_option == 1 || _option == 2, "Invalid validation option");
    require(
      Validations[_tokenId][_id].assigned == true, 
      "Not assigned to miner"
    );
    require(
      Validations[_tokenId][_id].opening == ValidationStatus.Neutral, 
      "Opening vote already cast"
    );
    if (_option == 1) {
      Validations[_tokenId][_id].opening = ValidationStatus.Positive;
      PredictionStats[_id].upvoteCount += 1;
    } else {
      Validations[_tokenId][_id].opening = ValidationStatus.Negative;
      PredictionStats[_id].downvoteCount += 1;
    }

    if (PredictionStats[_id].upvoteCount == SIXTY_PERCENT) {
      //prediction receives 60% positive validations
      PredictionStats[_id].state = State.Active;
      addToActivePool(_id);
    }

    if (PredictionStats[_id].downvoteCount == SIXTY_PERCENT) {
      //prediction receives 60% negative validations
      PredictionStats[_id].state = State.Rejected;
    }

    uint256 minerBonus = miningFee / MAX_VALIDATORS;
    Balances[msg.sender] += minerBonus; //miner recieves mining bonus.

    emit OpeningVoteSubmitted(_id, _tokenId, _option, PredictionStats[_id].state);
  }


  ///@dev Users can purchase prediction by sending purchase fee in the transaction
  ///@param _id prediction ID
  ///@param _key encrypted key of purchaser

  function purchasePrediction(uint256 _id, string memory _key)
    external
    payable
    override
    predictionEventNotStarted(_id)
    predictionActive(_id)
  {
    if(msg.value < Predictions[_id].price){
      require(Balances[msg.sender] >= (Predictions[_id].price - msg.value), "Insufficient balance");
      Balances[msg.sender] -= (Predictions[_id].price - msg.value);
    }else{
      uint256 bal = msg.value - Predictions[_id].price;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }
    Purchases[msg.sender][_id].purchased = true;
    PredictionStats[_id].buyCount += 1;
    BoughtPredictions[msg.sender].push(_id);
    emit PredictionPurchased(_id, msg.sender, _key);
  }


  ///@dev miner submits closing validation decision on seller's prediction.
  ///@param _id Prediction ID
  ///@param _tokenId Miner's NFT token Id
  ///@param _option Miner's validation decision

  function submitClosingVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  ) external override {
    require(_option == 1 || _option == 2, "Invalid validation option");
    require(
      (block.timestamp > Predictions[_id].endTime + (2 * HOURS) &&
        block.timestamp < Predictions[_id].endTime + (6 * HOURS)),
      "Can't cast closing vote now"
    );

    require(
      Validations[_tokenId][_id].assigned == true, 
      "Not assigned to miner"
    );
    require(
      Validations[_tokenId][_id].closing == ValidationStatus.Neutral, 
      "Opening vote already cast"
    );

    if (_option == 1) {
      Validations[_tokenId][_id].closing = ValidationStatus.Positive;
      PredictionStats[_id].wonVoteCount += 1;
    } else {
      Validations[_tokenId][_id].closing = ValidationStatus.Negative;
      PredictionStats[_id].lostVoteCount += 1;
    }
    _withdrawNFT(_tokenId);

    emit ClosingVoteSubmitted(_id, _tokenId, _option);
  }


  // ///@notice seller can only conclude transaction after games ended and cooled down
  // ///@dev Seller concludes transaction and settles all parties, depending on the prediction outcome.
  // ///@param _UID Prediction ID.
  // ///@param _sellerVote seller vote would only be using to break tie in miners closing votes.
  // // function concludeTransaction(uint256 _UID, bool _sellerVote)
  // //   external
  // //   override
  // // {
  // //   require(
  // //     !Predictions[_UID].withdrawnEarnings,
  // //     "Transaction already concluded"
  // //   );
  // //   ValidationStatus _winningOpeningVote = _getWinningOpeningVote(_UID);
  // //   ValidationStatus _winningClosingVote = _getWinningClosingVote(_UID);
  // //   Predictions[_UID].winningOpeningVote = _winningOpeningVote;
  // //   Predictions[_UID].winningClosingVote = _winningClosingVote;

  // //   if (block.timestamp > Predictions[_UID].endTime + (TWENTY_FOUR_HOURS * 3)) {
  // //     Predictions[_UID].withdrawnEarnings = true;
  // //     Predictions[_UID].state = State.Concluded;
  // //     lockFunds(Predictions[_UID].seller, sellerStakingFee);
  // //     Balances[msg.sender] += remenantOfMiningFee(_UID); //refund remenant of mining fee;
  // //     return;
  // //   }
  //   // _setUpSellerClosing(Predictions[_UID], _sellerVote);
  //   // _refundMinerStakingFee(
  //   //   Predictions[_UID],
  //   //   _winningOpeningVote,
  //   //   _winningClosingVote
  //   // );

  //   // if (Predictions[_UID].status == Status.Won) {
  //   //   uint256 minersShare = ((Predictions[_UID].validatorCount) *
  //   //     minerPercentage *
  //   //     (Predictions[_UID].totalEarned)) / 100;
  //   //   uint256 _sellerShare = Predictions[_UID].totalEarned - minersShare;
  //   //   uint256 _minerPercentageAmount = (Predictions[_UID].totalEarned *
  //   //     minerPercentage) / 100;
  //   //   Balances[Predictions[_UID].seller] += _sellerShare;
  //   //   for (uint256 index = 0; index < Predictions[_UID].votes.length; index++) {
  //   //     if (Predictions[_UID].votes[index].correctValidation) {
  //   //       Balances[
  //   //         Predictions[_UID].votes[index].miner
  //   //       ] += _minerPercentageAmount;
  //   //     }
  //   //   }
  //   // } else {
  //   //   for (
  //   //     uint256 index = 0;
  //   //     index < Predictions[_UID].buyersList.length;
  //   //     index++
  //   //   ) {
  //   //     Balances[Predictions[_UID].buyersList[index]] += Predictions[_UID]
  //   //       .price;
  //   //   }
  //   // }
  //   // Predictions[_UID].withdrawnEarnings = true;

  //   // emit TransactionConcluded(_UID, Predictions[_UID].status);
  // //}

  // ///@notice Upon miner successful opening validation, prediction ID is added to miner's validation list
  // ///@dev Miners can remove validation records [in batch] on successfull conclusion.
  // ///@param _UIDs list of validation records to be removed

  // function removeFromOwnedValidations(uint256[] calldata _UIDs)
  //   external
  //   override
  // {
  //   require(OwnedValidations[msg.sender].length > 0, "No owned validations");
  //   for (uint256 index = 0; index < _UIDs.length; index++) {
  //     if (
  //       ActiveValidations[_UIDs[index]][msg.sender] &&
  //       Predictions[_UIDs[index]].state == State.Concluded
  //     ) {
  //       ActiveValidations[_UIDs[index]][msg.sender] = false;
  //     }
  //   }
  // }

  // ///@notice Upon seller successful prediction upload, prediction ID is added to seller's predictions list
  // ///@dev Seller can remove prediction records [in batch] on successfull conclusion.
  // ///@param _UIDs list of prediction records to be removed

  // function removeFromOwnedPredictions(uint256[] calldata _UIDs)
  //   external
  //   override
  // {
  //   require(OwnedPredictions[msg.sender].length > 0, "No active predictions");
  //   for (uint256 index = 0; index < _UIDs.length; index++) {
  //     if (
  //       ActiveSoldPredictions[_UIDs[index]][msg.sender] &&
  //       Predictions[_UIDs[index]].state == State.Concluded
  //     ) {
  //       ActiveSoldPredictions[_UIDs[index]][msg.sender] = false;
  //     }
  //   }
  // }

  // ///@notice Upon buyer successful prediction purchase, prediction ID is added to purchaser's predictions list
  // ///@dev User can remove prediction records [in batch] on successfull conclusion.
  // ///@param _UIDs list of prediction records to be removed
  // function removeFromBoughtPredictions(uint256[] calldata _UIDs)
  //   external
  //   override
  // {
  //   require(BoughtPredictions[msg.sender].length > 0, "No bought predictions");
  //   for (uint256 index = 0; index < _UIDs.length; index++) {
  //     if (
  //       ActiveBoughtPredictions[_UIDs[index]][msg.sender] &&
  //       Predictions[_UIDs[index]].state == State.Concluded
  //     ) {
  //       ActiveBoughtPredictions[_UIDs[index]][msg.sender] = false;
  //     }
  //   }
  // }

  // ///@dev Withdraw funds from the contract
  // ///@param _amount Amount to be withdrawn

  // function withdrawFunds(uint256 _amount) external isOpen {
  //   require(Balances[msg.sender] >= _amount, "Not enough balance");
  //   Balances[msg.sender] -= _amount;
  //   // attempt to send the funds to the recipient
  //   (bool success, ) = payable(msg.sender).call{value: _amount}("");
  //   // if it failed, update their credit balance so they can pull it later
  //   if (!success) {
  //     Balances[msg.sender] += _amount;
  //   }

  //   emit Withdrawal(msg.sender, _amount, Balances[msg.sender]);
  // }

  // ///@notice Sellers can only create a verified username after surpassing a minimum number of won predictions
  // ///@dev Seller create a verified username
  // ///@param _username Supplied username

  // function createUsername(bytes32 _username) external {
  //   require(
  //     UserProfile[msg.sender].wonCount >= minWonCountForVerification,
  //     "Not enough total predictions"
  //   );
  //   require(_username != bytes32(0), "Username cannot be null");
  //   require(
  //     UserProfile[msg.sender].username == bytes32(0),
  //     "Username already exists"
  //   );
  //   UserProfile[msg.sender].username = _username;
  //   emit UsernameCreated(msg.sender, _username);
  // }

  // ///@dev Withdraw locked funds to contract balance.
  // ///@param _amount Amount to be withdrawn

  // function transferLockedFunds(uint256 _amount) external {
  //   require(LockedFunds[msg.sender].amount > _amount, "Not enough balance");
  //   require(
  //     block.timestamp > LockedFunds[msg.sender].releaseDate,
  //     "Assets still frozen"
  //   );
  //   LockedFunds[msg.sender].amount -= _amount;
  //   Balances[msg.sender] += _amount;

  //   emit LockedFundsTransferred(
  //     msg.sender,
  //     _amount,
  //     LockedFunds[msg.sender].amount
  //   );
  // }

  // ///@notice in this case, the prediction didn't make it to the active state ( < 60% positive opening validations )
  // ///@dev Miner withdraws NFT and staking fee
  // ///@param _UID Prediction ID
  // ///@param _tokenId NFT tokenID

  // function withdrawMinerNftandStakingFee(uint256 _UID, uint256 _tokenId)
  //   external
  //   override
  //   isNftOwner(_tokenId)
  //   predictionEventAlreadyStarted(_UID)
  // {
  //   require(
  //     Predictions[_UID].state == State.Inactive ||
  //       Predictions[_UID].state == State.Denied,
  //     "Prediction not inactive"
  //   );
  //   _returnNftAndStakingFee(_UID, _tokenId);
  //   emit MinerNFTAndStakingFeeWithdrawn(_UID, _tokenId, msg.sender);
  // }

  // ///@notice In this very rare case, a buyer purchases a prediction that didn't go active or was withdrawn
  // ///@dev Buyer is refunded of purchase fee
  // ///@param _UID Prediction ID

  // function buyerRefund(uint256 _UID)
  //   external
  //   override
  //   predictionEventAlreadyStarted(_UID)
  // {
  //   require(
  //     Predictions[_UID].state == State.Inactive ||
  //       Predictions[_UID].state == State.Denied,
  //     "Prediction not inactive"
  //   );
  //   _returnBuyerPurchaseFee(_UID);

  //   emit PurchaseRefunded(_UID, msg.sender);
  // }

  // ///@notice In this case, seller didn't conclude transaction within the set window period
  // ///@dev Refunds NFT and staking fee back to miner
  // ///@param _UID Prediction ID
  // ///@param _tokenId Miner NFT token Id

  // function inconclusiveMinerRefund(uint256 _UID, uint256 _tokenId)
  //   external
  //   override
  //   predictionClosingOverdue(_UID)
  //   isNftOwner(_tokenId)
  //   predictionActive(_UID)
  // {
  //   _returnNftAndStakingFee(_UID, _tokenId);
  //   emit MinerNFTAndStakingFeeWithdrawn(_UID, _tokenId, msg.sender);
  // }

  // ///@notice In this case, seller didn't conclude transaction within the set window period
  // ///@dev Refunds buyer prediction purchase fee
  // ///@param _UID Prediction ID

  // function inconclusiveBuyerRefund(uint256 _UID)
  //   external
  //   override
  //   predictionClosingOverdue(_UID)
  //   predictionActive(_UID)
  // {
  //   _returnBuyerPurchaseFee(_UID);

  //   emit PurchaseRefunded(_UID, msg.sender);
  // }

  // ///@notice In this case, Prediction got > 0% & < 60% positive opening validations so couldn't make it to active state
  // ///@dev Refunds prediction seller's staking fee
  // ///@param _UID Prediction ID

  // function refundSellerStakingFee(uint256 _UID)
  //   external
  //   override
  //   onlySeller(_UID)
  //   predictionEventAlreadyStarted(_UID)
  // {
  //   require(
  //     Predictions[_UID].state == State.Inactive,
  //     "Prediction not inactive"
  //   );
  //   require(
  //     !Predictions[_UID].sellerStakingFeeRefunded,
  //     "Staking fee already refunded"
  //   );
  //   Predictions[_UID].sellerStakingFeeRefunded = true;
  //   Balances[Predictions[_UID].seller] += sellerStakingFee;
  //   emit SellerStakingFeeRefunded(_UID, Predictions[_UID].seller);
  // }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  receive() external payable {
    Balances[msg.sender] += msg.value;
  }
}
