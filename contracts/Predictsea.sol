// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";
import "./Seller.sol";
import "./Miner.sol";
import "./Buyer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// @title PredictSea {Blockchain powered sport prediction marketplace}

contract Predictsea is IERC721Receiver, Seller, Miner, Buyer {
  /*╔═════════════════════════════╗
    ║           EVENTS            ║
    ╚═════════════════════════════╝*/

  event PredictionCreated(
    address indexed sender,
    uint256 indexed UID,
    uint256 startTime,
    uint256 endTime,
    uint16 odd,
    uint256 price
  );
  event DepositCreated(address sender, uint256 value);

  event ValidationRequested(
    uint256 indexed UID,
    uint256 indexed tokenId,
    address miner,
    bytes32 payload
  );
  event VoteSubmitted(
    uint256 indexed UID,
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
  event PredictionUpdated(
    uint256 indexed UID,
    address indexed sender,
    uint256 startTime,
    uint256 endTime,
    uint16 odd,
    uint256 price
  );
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
  constructor(
    address _NFTAddress,
    uint256 _miningFee,
    uint256 _sellerStakingFee,
    uint256 _minerStakingFee,
    uint32 _minerPercentage,
    uint16 _minWonCountForVerification
  ) {
    owner = payable(msg.sender);
    NFT_CONTRACT_ADDRESS = _NFTAddress;
    miningFee = _miningFee;
    sellerStakingFee = _sellerStakingFee;
    minerStakingFee = _minerStakingFee;
    minerPercentage = _minerPercentage;
    minWonCountForVerification = _minWonCountForVerification;
  }


 //Seller creates prediction and pays staking fee with wallet balance (non-payable)

  function createPredictionWithWallet(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external override {
    uint256 total = miningFee + sellerStakingFee;
    require(Balances[msg.sender] >= total, "Not enough balance");
    Balances[msg.sender] -= total;

    _setupPrediction(_UID, _startTime, _endTime, _odd, _price);
    emit PredictionCreated(
      msg.sender,
      _UID,
      _startTime,
      _endTime,
      _odd,
      _price
    );
  }

  // Seller creates prediction and pays staking fee by sending required wei in transaction (payable)
  
  function createPrediction(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external payable override {
    uint256 total = miningFee + sellerStakingFee;
    require(msg.value >= total, "Not enough ether");
    uint256 bal = msg.value - total;
    if (bal > 0) {
      Balances[msg.sender] += bal;
    }

    _setupPrediction(_UID, _startTime, _endTime, _odd, _price);
    emit PredictionCreated(
      msg.sender,
      _UID,
      _startTime,
      _endTime,
      _odd,
      _price
    );
  }

  function withdrawPrediction(uint256 _UID)
    external
    override
    onlySeller(_UID)
    notMined(_UID)
  {
    _refundSellerStakingFee(Predictions[_UID]);
    Predictions[_UID].state = State.Withdrawn;

    emit PredictionWithdrawn(_UID, msg.sender);
  }

  function updatePrediction(
    uint256 _UID,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external override onlySeller(_UID) notMined(_UID) {
    _setupPrediction(_UID, _startTime, _endTime, _odd, _price);

    emit PredictionUpdated(
      _UID,
      msg.sender,
      _startTime,
      _endTime,
      _odd,
      _price
    );
  }

  function requestValidationWithWallet(
    uint256 _UID,
    uint256 _tokenId,
    bytes32 payload
  ) external override {
    require(Balances[msg.sender] >= minerStakingFee, "Not enough balance");
    Balances[msg.sender] -= minerStakingFee;
    _transferNftToContract(_tokenId);
    _setUpValidationRequest(_tokenId, _UID);
    emit ValidationRequested(_UID, _tokenId, msg.sender, payload);
  }

  function requestValidation(
    uint256 _UID,
    uint256 _tokenId,
    bytes32 payload
  ) external payable override {
    require(msg.value >= minerStakingFee, "Not enough balance");
    _transferNftToContract(_tokenId);
    _setUpValidationRequest(_tokenId, _UID);
    Predictions[_UID].validators[_tokenId].miner = TokenOwner[_tokenId];
    emit ValidationRequested(_UID, _tokenId, msg.sender, payload);
  }

  function submitOpeningVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _option
  ) external override {
    require(_option == 1 || _option == 2, "Invalid validation option");

    Vote storage _vote = _setUpOpeningVote(_UID, _tokenId);
    if (_option == 1) {
      _vote.opening = ValidationStatus.Positive;
      Predictions[_UID].positiveOpeningVoteCount += 1;
    } else {
      _vote.opening = ValidationStatus.Negative;
      Predictions[_UID].negativeOpeningVoteCount += 1;
    }

    if (Predictions[_UID].positiveOpeningVoteCount == SIXTY_PERCENT) {
      //prediction receives 60% positive validations
      Predictions[_UID].state = State.Active;
    }
    if (Predictions[_UID].negativeOpeningVoteCount >= EIGHTY_PERCENT) {
      Predictions[_UID].state = State.Denied;
      lockFunds(Predictions[_UID].seller, sellerStakingFee);
    }

    uint256 minerBonus = miningFee / MAX_VALIDATORS;
    Balances[msg.sender] += minerBonus; //miner recieves mining bonus.

    emit VoteSubmitted(_UID, _tokenId, _option, Predictions[_UID].state);
  }

  function updateMinerOpeningVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _vote
  ) external override isNftOwner(_tokenId) {
    require(
      Predictions[_UID].state == State.Inactive,
      "Prediction already active"
    );
    ValidationStatus _status = _getMinerOpeningPredictionVote(_UID, _tokenId);
    require(
      _status != ValidationStatus.Neutral &&
        _status != ValidationStatus.Assigned,
      "Didn't vote previously"
    );
    require(_vote > 1 && _vote <= 3, "Vote cannot be neutral");
    if (_vote == 2) {
      require(
        _status != ValidationStatus.Positive,
        "same as previous vote option"
      );
      Predictions[_UID].validators[_tokenId].opening = ValidationStatus
        .Positive;
      Predictions[_UID].negativeOpeningVoteCount -= 1;
      Predictions[_UID].positiveOpeningVoteCount += 1;
    } else {
      require(
        _status != ValidationStatus.Negative,
        "same as previous vote option"
      );
      Predictions[_UID].validators[_tokenId].opening = ValidationStatus
        .Negative;
      Predictions[_UID].positiveOpeningVoteCount -= 1;
      Predictions[_UID].negativeOpeningVoteCount += 1;
    }

    if (Predictions[_UID].positiveOpeningVoteCount == SIXTY_PERCENT) {
      //prediction receives 60% positive validations
      Predictions[_UID].state = State.Active;
    }
    emit MinerOpeningVoteUpdated(_UID, _tokenId, _vote);
  }

  function purchasePredictionWithWallet(uint256 _UID, string calldata email)
    external
    override
  {
    require(
      Balances[msg.sender] >= Predictions[_UID].price,
      "Insufficient balance"
    );
    Balances[msg.sender] -= Predictions[_UID].price;
    _setUpPurchase(_UID);
    emit PredictionPurchased(_UID, msg.sender, email);
  }

  function purchasePrediction(uint256 _UID, string calldata email)
    external
    payable
    override
  {
    require(msg.value >= Predictions[_UID].price, "Not enough ether");
    _setUpPurchase(_UID);
    emit PredictionPurchased(_UID, msg.sender, email);
  }

  function submitClosingVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _option
  ) external override {
    require(_option == 1 || _option == 2, "Invalid validation option");

    Vote storage _vote = _setUpClosingVote(_UID, _tokenId);
    if (_option == 1) {
      _vote.closing = ValidationStatus.Positive;
      Predictions[_UID].positiveClosingVoteCount += 1;
    } else {
      _vote.closing = ValidationStatus.Negative;
      Predictions[_UID].negativeClosingVoteCount += 1;
    }
    Predictions[_UID].votes.push(_vote);
    _withdrawNFT(_tokenId);

    emit ClosingVoteSubmitted(_UID, _tokenId, _option);
  }

  function updateMinerClosingVote(
    uint256 _UID,
    uint256 _tokenId,
    uint8 _vote
  ) external override isNftOwner(_tokenId) {
    require(
      Predictions[_UID].validators[_tokenId].closing ==
        ValidationStatus.Positive ||
        Predictions[_UID].validators[_tokenId].closing ==
        ValidationStatus.Negative,
      "Closing vote not cast yet!"
    );
    /**Cool down period is 6hrs (21600 secs) after the game ends */
    require(
      (block.timestamp > Predictions[_UID].endTime + SIX_HOURS &&
        block.timestamp < Predictions[_UID].endTime + TWELVE_HOURS),
      "Event not cooled down"
    );

    require(_vote > 1 && _vote <= 3, "Vote cannot be neutral");
    ValidationStatus _status = _getMinerClosingPredictionVote(_UID, _tokenId);
    if (_vote == 2) {
      require(
        _status != ValidationStatus.Positive,
        "same as previous vote option"
      );
      Predictions[_UID].validators[_tokenId].closing = ValidationStatus
        .Positive;
      Predictions[_UID].negativeClosingVoteCount -= 1;
      Predictions[_UID].positiveClosingVoteCount += 1;
    } else {
      require(
        _status != ValidationStatus.Negative,
        "same as previous vote option"
      );
      Predictions[_UID].validators[_tokenId].closing = ValidationStatus
        .Negative;
      Predictions[_UID].positiveClosingVoteCount -= 1;
      Predictions[_UID].negativeClosingVoteCount += 1;
    }

    emit MinerClosingVoteUpdated(_UID, _tokenId, _vote);
  }

  function concludeTransaction(uint256 _UID, bool _sellerVote)
    external
    override
  {
    require(
      !Predictions[_UID].withdrawnEarnings,
      "Transaction already concluded"
    );
    ValidationStatus _winningOpeningVote = _getWinningOpeningVote(_UID);
    ValidationStatus _winningClosingVote = _getWinningClosingVote(_UID);
    Predictions[_UID].winningOpeningVote = _winningOpeningVote;
    Predictions[_UID].winningClosingVote = _winningClosingVote;

    if (block.timestamp > Predictions[_UID].endTime + (TWENTY_FOUR_HOURS * 3)) {
      lockFunds(Predictions[_UID].seller, sellerStakingFee);
      Predictions[_UID].withdrawnEarnings = true;
      Predictions[_UID].state = State.Concluded;

      return;
    }
    _setUpSellerClosing(Predictions[_UID], _sellerVote);
    _refundMinerStakingFee(
      Predictions[_UID],
      _winningOpeningVote,
      _winningClosingVote
    );

    if (Predictions[_UID].status == Status.Won) {
      uint256 minersShare = ((Predictions[_UID].validatorCount) *
        minerPercentage *
        (Predictions[_UID].totalEarned)) / 100;
      uint256 _sellerShare = Predictions[_UID].totalEarned - minersShare;
      uint256 _minerPercentageAmount = (Predictions[_UID].totalEarned *
        minerPercentage) / 100;
      Balances[Predictions[_UID].seller] += _sellerShare;
      for (uint256 index = 0; index < Predictions[_UID].votes.length; index++) {
        if (Predictions[_UID].votes[index].correctValidation) {
          Balances[
            Predictions[_UID].votes[index].miner
          ] += _minerPercentageAmount;
        }
      }
    } else {
      for (
        uint256 index = 0;
        index < Predictions[_UID].buyersList.length;
        index++
      ) {
        Balances[Predictions[_UID].buyersList[index]] += Predictions[_UID]
          .price;
      }
    }
    Predictions[_UID].withdrawnEarnings = true;

    emit TransactionConcluded(_UID, Predictions[_UID].status);
  }

  function removeFromOwnedValidations(uint256[] calldata _UIDs)
    external
    override
  {
    require(OwnedValidations[msg.sender].length > 0, "No owned validations");
    for (uint256 index = 0; index < _UIDs.length; index++) {
      if (
        ActiveValidations[_UIDs[index]][msg.sender] &&
        Predictions[_UIDs[index]].state == State.Concluded
      ) {
        ActiveValidations[_UIDs[index]][msg.sender] = false;
      }
    }
  }

  function removeFromOwnedPredictions(uint256[] calldata _UIDs)
    external
    override
  {
    require(OwnedPredictions[msg.sender].length > 0, "No active predictions");
    for (uint256 index = 0; index < _UIDs.length; index++) {
      if (
        ActiveSoldPredictions[_UIDs[index]][msg.sender] &&
        Predictions[_UIDs[index]].state == State.Concluded
      ) {
        ActiveSoldPredictions[_UIDs[index]][msg.sender] = false;
      }
    }
  }

  function removeFromBoughtPredictions(uint256[] calldata _UIDs)
    external
    override
  {
    require(BoughtPredictions[msg.sender].length > 0, "No bought predictions");
    for (uint256 index = 0; index < _UIDs.length; index++) {
      if (
        ActiveBoughtPredictions[_UIDs[index]][msg.sender] &&
        Predictions[_UIDs[index]].state == State.Concluded
      ) {
        ActiveBoughtPredictions[_UIDs[index]][msg.sender] = false;
      }
    }
  }

  function ownerOfNft(uint256 _tokenId) external view returns (address) {
    return TokenOwner[_tokenId];
  }

  function withdrawFunds(uint256 _amount) external {
    require(Balances[msg.sender] >= _amount, "Not enough balance");
    Balances[msg.sender] -= _amount;
    // attempt to send the funds to the recipient
    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    // if it failed, update their credit balance so they can pull it later
    if (!success) {
      Balances[msg.sender] += _amount;
    }

    emit Withdrawal(msg.sender, _amount, Balances[msg.sender]);
  }

  function createUsername(bytes32 _username) external {
    require(
      UserProfile[msg.sender].wonCount >= minWonCountForVerification,
      "Not enough total predictions"
    );
    require(_username != bytes32(0), "Username cannot be null");
    require(
      UserProfile[msg.sender].username == bytes32(0),
      "Username already exists"
    );
    UserProfile[msg.sender].username = _username;
    emit UsernameCreated(msg.sender, _username);
  }

  function transferLockedFunds(uint256 _amount) external {
    require(LockedFunds[msg.sender].amount > _amount, "Not enough balance");
    require(
      block.timestamp > LockedFunds[msg.sender].releaseDate,
      "Assets still frozen"
    );
    LockedFunds[msg.sender].amount -= _amount;
    Balances[msg.sender] += _amount;

    emit LockedFundsTransferred(
      msg.sender,
      _amount,
      LockedFunds[msg.sender].amount
    );
  }

  //in this case, the prediction didn't make it to the active state
  function withdrawMinerNftandStakingFee(uint256 _tokenId, uint256 _UID)
    external
    override
    isNftOwner(_tokenId)
    predictionEventAlreadyStarted(_UID)
  {
    require(
      Predictions[_UID].state == State.Inactive ||
        Predictions[_UID].state == State.Denied,
      "Prediction not inactive"
    );
    _returnNftAndStakingFee(_UID, _tokenId);
    emit MinerNFTAndStakingFeeWithdrawn(_UID, _tokenId, msg.sender);
  }

  function buyerRefund(uint256 _UID)
    external
    override
    predictionEventAlreadyStarted(_UID)
  {
    require(
      Predictions[_UID].state == State.Inactive ||
        Predictions[_UID].state == State.Denied,
      "Prediction not inactive"
    );
    _returnBuyerPurchaseFee(_UID);

    emit PurchaseRefunded(_UID, msg.sender);
  }

  function inconclusiveMinerRefund(uint256 _UID, uint256 _tokenId)
    external
    override
    predictionClosingOverdue(_UID)
    isNftOwner(_tokenId)
    predictionActive(_UID)
  {
    _returnNftAndStakingFee(_UID, _tokenId);
    emit MinerNFTAndStakingFeeWithdrawn(_UID, _tokenId, msg.sender);
  }

  function inconclusiveBuyerRefund(uint256 _UID)
    external
    override
    predictionClosingOverdue(_UID)
    predictionActive(_UID)
  {
    _returnBuyerPurchaseFee(_UID);

    emit PurchaseRefunded(_UID, msg.sender);
  }

  function refundSellerStakingFee(uint256 _UID)
    external
    override
    onlySeller(_UID)
    predictionEventAlreadyStarted(_UID)
  {
    require(
      Predictions[_UID].state == State.Inactive,
      "Prediction not inactive"
    );
    require(
      !Predictions[_UID].sellerStakingFeeRefunded,
      "Staking fee already refunded"
    );
    Predictions[_UID].sellerStakingFeeRefunded = true;
    Balances[Predictions[_UID].seller] += sellerStakingFee;
    emit SellerStakingFeeRefunded(_UID, Predictions[_UID].seller);
  }

  function setMiningFee(uint256 amount) external onlyOwner {
    miningFee = amount;
  }

  function setSellerStakingFee(uint256 amount) external onlyOwner {
    sellerStakingFee = amount;
  }

  function setMinerStakingFee(uint256 amount) external onlyOwner {
    minerStakingFee = amount;
  }

  function setMinerPercentage(uint32 percent) external onlyOwner {
    minerPercentage = percent;
  }

  

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
    emit DepositCreated(msg.sender, msg.value);
  }
}
