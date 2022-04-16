// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title PredictSea {Blockchain powered sport prediction marketplace}

contract Predictsea is Ownable, IERC721Receiver {
  using Counters for Counters.Counter;

  Counters.Counter private _predictionIds;

  uint256 private pointer;

    // ========== STATE VARIABLES ========== //

  ///@notice maps the generated id to the prediction data
  mapping(uint256 => PredictionData) public Predictions;

  ///@notice maps the generated id to the prediction stats
  mapping(uint256 => Statistics) public PredictionStats;

  //      tokenId          prediction id
  mapping(uint256 => mapping(uint256 => Vote)) public Validations; //maps miners tokenId to vote data

  //    buyer address    prediction id
  mapping(address => mapping(uint256 => PurchaseData)) public Purchases;

  //      predictionId => activePool index
  mapping(uint256 => uint256) public Index;

  mapping(address => uint256) public Balances;

  mapping(address => LockedFundsData) public LockedFunds;

  address public NFT_CONTRACT_ADDRESS;

  uint8 internal constant SIXTY_PERCENT = 3;

  uint8 internal constant MAX_VALIDATORS = 5;

  uint16 internal constant HOURS = 3600;

  mapping(address => uint256[]) public BoughtPredictions;

  mapping(address => uint256[]) public OwnedPredictions;

  mapping(address => ValidationData[]) public OwnedValidations;

  mapping(uint256 => address) public TokenOwner;

  mapping(address => Profile) public User;

  mapping(address => uint256[]) public dummyList; 

  mapping(address => ValidationData[]) public dummyValidations;

  enum Status {
    Pending,
    Won,
    Lost,
    Inconclusive
  }

  enum State {
    Inactive,
    Withdrawn,
    Rejected,
    Active,
    Concluded
  }

  enum ValidationStatus {
    Neutral,
    Positive,
    Negative
  }

  struct LockedFundsData {
    uint256 amount;
    uint256 lastPushDate;
    uint256 releaseDate;
    uint256 totalInstances;
  }

  struct Vote {
    address miner;
    bool assigned;
    ValidationStatus opening;
    ValidationStatus closing;
    bool settled;
  }

  struct PredictionData {
    address seller;
    string ipfsHash;
    string key;
    uint256 createdAt;
    uint256 startTime; //start time of first predicted event
    uint256 endTime; //end time of last predicted event
    uint16 odd;
    uint256 price;
    Status status;
    State state;
    bool withdrawnEarnings;
    ValidationStatus winningOpeningVote;
    ValidationStatus winningClosingVote;
  }

  struct Statistics {
    uint8 validatorCount;
    uint8 upvoteCount;
    uint8 downvoteCount;
    uint8 wonVoteCount;
    uint8 lostVoteCount;
    uint64 buyCount;
  }

  struct PurchaseData {
    bool purchased;
    string key;
    bool refunded;
  }

  struct ValidationData {
    uint256 id;
    uint256 tokenId;
    string key;
  }

  struct Profile {
    string profile;
    string key;
    uint256 wonCount;
    uint256 lostCount;
    uint256 totalPredictions;
    uint256 totalOdds;
    uint256 grossWinnings;
    uint256[30] last30Predictions;
    uint8 spot;
  }

  uint256 public miningFee; // paid by seller -> to be shared by validators
  uint256 public minerStakingFee; // paid by miner, staked per validation
  uint32 public minerPercentage; // %  for miner, In event of a prediction won

  uint256[] public miningPool;
  uint256[] public activePool;

 

  
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
  event PredictionPurchased(address indexed buyer, uint256 indexed id);
  event ClosingVoteSubmitted(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint8 option
  );

  event PredictionWithdrawn(uint256 indexed id, address seller);

  event MinerSettled(
    address indexed miner,
    uint256 indexed id,
    uint256 indexed tokenId,
    uint256 minerEarnings,
    bool refunded
  );

  event SellerSettled(
    address indexed seller,
    uint256 indexed id,
    uint256 sellerEarnings
  );

  event BuyerRefunded(address indexed buyer, uint256 indexed id, uint256 price);

  event Withdrawal(address indexed recipient, uint256 amount, uint256 balance);

  event MinerNFTAndStakingFeeWithdrawn(
    address indexed seller,
    uint256 indexed id,
    uint256 indexed tokenId
  );

  event LockedFundsTransferred(
    address indexed user,
    uint256 amount,
    uint256 lockedBalance
  );

  /*╔═════════════════════════════╗
    ║             END             ║
    ║            EVENTS           ║
    ╚═════════════════════════════╝*/

   /**********************************/
  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  modifier onlySeller(uint256 _id) {
    require(msg.sender == Predictions[_id].seller, "Only prediction seller");
    _;
  }

  modifier notSeller(uint256 _id) {
    require(msg.sender != Predictions[_id].seller, "Seller Unauthorized!");
    _;
  }

  modifier predictionMeetsMinimumRequirements(
    uint256 _startTime,
    uint256 _endTime
  ) {
    require(
      _sellerDoesMeetMinimumRequirements(_startTime, _endTime),
      "Doesn't meet min requirements"
    );

    _;
  }

  modifier hasMinimumBalance(uint256 _amount) {
    require(Balances[msg.sender] >= _amount, "Not enough balance");

    _;
  }

  modifier predictionEventNotStarted(uint256 _id) {
    require(
      Predictions[_id].startTime > block.timestamp,
      "Event already started"
    );
    _;
  }

  modifier predictionEventEnded(uint256 _UID) {
    require(block.timestamp > Predictions[_UID].endTime, "Event not started");
    _;
  }

  modifier validatorCountIncomplete(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount < MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }

  modifier validatorCountComplete(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount == MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }

  modifier predictionActive(uint256 _id) {
    require(
      Predictions[_id].state == State.Active,
      "Prediction currently inactive"
    );
    _;
  }

  modifier notMined(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount == 0,
      "Prediction already mined"
    );
    _;
  }

  modifier isNftOwner(uint256 _tokenId) {
    require(TokenOwner[_tokenId] == msg.sender, "Not NFT Owner");
    _;
  }

  modifier assignedToMiner(uint256 _id, uint256 _tokenId) {
    require(
      Validations[_tokenId][_id].assigned == true,
      "Not assigned to miner"
    );

    _;
  }

  /**********************************/
  /*╔═════════════════════════════╗
    ║             END             ║
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/
  /**********************************/

  // constructor
  constructor() {
    owner = payable(msg.sender);
  }

  //internal functions


  function purchasedPredictionsCleanup() internal {
    if(BoughtPredictions[msg.sender].length == 0){
      return;
    }
    for (uint256 index = 0; index < BoughtPredictions[msg.sender].length; index++) {
      uint256 _id = BoughtPredictions[msg.sender][index];

      if((Predictions[_id].winningClosingVote == ValidationStatus.Neutral) || (Predictions[_id].winningClosingVote == ValidationStatus.Negative))
      {
        if(Purchases[msg.sender][_id].refunded == false){
          dummyList[msg.sender].push(_id);
        }
                   
      }

    }
    BoughtPredictions[msg.sender] = dummyList[msg.sender];
    delete dummyList[msg.sender];
  }



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
    Validations[_tokenId][current].miner = msg.sender;
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
    
    if(LockedFunds[_user].lastPushDate == 0){
      LockedFunds[_user].releaseDate = add(block.timestamp, mul(mul(24, HOURS), 30));
    }else{
      LockedFunds[_user].releaseDate += mul(mul(24, HOURS), 30);
    }
    LockedFunds[_user].lastPushDate = block.timestamp;
    LockedFunds[_user].totalInstances += 1;
  }

  function ownedValidationsCleanup() internal {
    if(OwnedValidations[msg.sender].length == 0){
      return;
    }
    for (uint256 index = 0; index < OwnedValidations[msg.sender].length; index++) {
      ValidationData memory _validation = OwnedValidations[msg.sender][index];

      if(Validations[_validation.tokenId][_validation.id].settled == false){
        
          dummyValidations[msg.sender].push(_validation);
             
      }
    }
    OwnedValidations[msg.sender] = dummyValidations[msg.sender];
    delete dummyValidations[msg.sender];
  }



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


  function ownedPredictionsCleanup() internal {
    if(OwnedPredictions[msg.sender].length == 0){
      return;
    }
    for (uint256 index = 0; index < OwnedPredictions[msg.sender].length; index++) {
      uint256 _id = OwnedPredictions[msg.sender][index];
      if(Predictions[_id].state != State.Withdrawn || Predictions[_id].state != State.Rejected){
        continue;
      }
      if((Predictions[_id].winningClosingVote == ValidationStatus.Neutral) || (Predictions[_id].winningClosingVote == ValidationStatus.Positive))
      {
        if(Predictions[_id].withdrawnEarnings == false){
          dummyList[msg.sender].push(_id);
        }
                   
      }
    }
    OwnedPredictions[msg.sender] = dummyList[msg.sender];
    delete dummyList[msg.sender];
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
    emit VariableUpdated(miningFee, minerStakingFee, minerPercentage);
  }

  ///@dev Allows owner to set NFT address
  ///@param _NftAddress Deployed NFT contract address

  function setNftAddress(address _NftAddress)
    external
    onlyOwner
    notZeroAddress(_NftAddress)
  {
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
  ) external payable  {
    if (msg.value < miningFee) {
      require(
        Balances[msg.sender] >= sub(miningFee, msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= sub(miningFee, msg.value);
    } else {
      uint256 bal = sub(msg.value, miningFee);
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    _predictionIds.increment();
    uint256 _id = _predictionIds.current();
    
    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    miningPool.push(_id);

    ownedPredictionsCleanup();
    OwnedPredictions[msg.sender].push(_id);
    

    emit PredictionCreated(msg.sender, _id, _ipfsHash, _key);
  }

  ///@notice Seller can withdraw prediction only before any miner has mined it.
  ///@param _id prediction Id

  function withdrawPrediction(uint256 _id)
    external
    onlySeller(_id)
    notMined(_id)
  {
    require(
      Predictions[_id].state != State.Withdrawn,
      "Prediction already withdrawn!"
    );
    Predictions[_id].state = State.Withdrawn;
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
  ) external  onlySeller(_id) notMined(_id) {
    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    emit PredictionUpdated(msg.sender, _id, _ipfsHash, _key);
  }

  ///@dev miner can place validation request and pay staking fee by sending it in the transaction
  ///@param _tokenId NFT token Id
  ///@param _key encrypted purchase key

  function requestValidation(uint256 _tokenId, string memory _key)
    external
    payable
    
  {
    if (msg.value < minerStakingFee) {
      require(
        Balances[msg.sender] >= (minerStakingFee - msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= (minerStakingFee - msg.value);
    } else {
      uint256 bal = msg.value - minerStakingFee;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    require(miningPool.length > 0, "mining pool empty");
     ownedValidationsCleanup();
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
  )
    external
    predictionEventNotStarted(_id)
    isNftOwner(_tokenId)
    assignedToMiner(_id, _tokenId)
  {
    require(_option == 1 || _option == 2, "Invalid validation option");
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
      Predictions[_id].state = State.Active;
      addToActivePool(_id);
    }

    if (PredictionStats[_id].downvoteCount == SIXTY_PERCENT) {
      //prediction receives 60% negative validations
      Predictions[_id].state = State.Rejected;
      delete miningPool[_id - 1]; //delete prediction entry from mining pool
    }

    uint256 minerBonus = miningFee / MAX_VALIDATORS;
    Balances[msg.sender] += minerBonus; //miner recieves mining bonus.

    emit OpeningVoteSubmitted(_id, _tokenId, _option, Predictions[_id].state);
  }

  ///@dev Users can purchase prediction by sending purchase fee in the transaction
  ///@param _id prediction ID
  ///@param _key encrypted key of purchaser

  function purchasePrediction(uint256 _id, string memory _key)
    external
    payable
    predictionEventNotStarted(_id)
    predictionActive(_id)
  {
    if (msg.value < Predictions[_id].price) {
      require(
        Balances[msg.sender] >= (Predictions[_id].price - msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= (Predictions[_id].price - msg.value);
    } else {
      uint256 bal = msg.value - Predictions[_id].price;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }
    purchasedPredictionsCleanup();
    Purchases[msg.sender][_id].purchased = true;
    Purchases[msg.sender][_id].key = _key;
    PredictionStats[_id].buyCount += 1;
    BoughtPredictions[msg.sender].push(_id);
    emit PredictionPurchased(msg.sender, _id);
  }

  ///@dev miner submits closing validation decision on seller's prediction.
  ///@param _id Prediction ID
  ///@param _tokenId Miner's NFT token Id
  ///@param _option Miner's validation decision

  function submitClosingVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  )
    external
    predictionActive(_id)
    isNftOwner(_tokenId)
    assignedToMiner(_id, _tokenId)
  {
    require(_option == 1 || _option == 2, "Invalid validation option");
    require(
      block.timestamp > Predictions[_id].endTime + (2 * HOURS),
      "Can't cast closing vote now"
    );

    require(
      Validations[_tokenId][_id].closing == ValidationStatus.Neutral,
      "Closing vote already cast"
    );

    require(
      block.timestamp < Predictions[_id].endTime + (6 * HOURS),
      "Vote window period expired"
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

  function withdrawMinerNftandStakingFee(uint256 _id, uint256 _tokenId)
    external
    assignedToMiner(_id, _tokenId)
    isNftOwner(_tokenId)
    
  {
    require(
      Predictions[_id].state == State.Rejected,
      "Prediction not rejected"
    );
    require(
      Validations[_tokenId][_id].settled == false,
      "Staking fee already refunded"
    );
    Validations[_tokenId][_id].settled = true;
    Balances[TokenOwner[_tokenId]] += minerStakingFee;
    _withdrawNFT(_tokenId);
    emit MinerNFTAndStakingFeeWithdrawn(msg.sender, _id, _tokenId);
  }

  


  function settleMiner(uint256 _id, uint256 _tokenId) external {
    require(Predictions[_id].state == State.Active || Predictions[_id].state == State.Concluded, "Not an active prediction");
    require(Validations[_tokenId][_id].miner == msg.sender, "Not miner");
    require(
      Validations[_tokenId][_id].settled == false,
      "Miner already settled"
    );
    require(
      block.timestamp > Predictions[_id].endTime + (6 * HOURS),
      "Not cooled down yet"
    );
    if (Predictions[_id].state == State.Active) {
      Predictions[_id].state = State.Concluded;
      Predictions[_id].winningOpeningVote = _getWinningOpeningVote(_id);
      Predictions[_id].winningClosingVote = _getWinningClosingVote(_id);
      addToRecentPredictionsList(Predictions[_id].seller, _id);
      removeFromActivePool(_id);
    }
    uint256 _minerEarnings = 0;
    bool _refunded = _refundMinerStakingFee(_id, _tokenId);
    if (Predictions[_id].winningClosingVote == ValidationStatus.Positive) {
      _minerEarnings =
        (Predictions[_id].price *
          PredictionStats[_id].buyCount *
          minerPercentage) /
        100;
      
    }

    Balances[Validations[_tokenId][_id].miner] += _minerEarnings;

    Validations[_tokenId][_id].settled = true;

    emit MinerSettled(msg.sender, _id, _tokenId, _minerEarnings, _refunded);
  }

  function refundBuyer(uint256 _id) external {
    require(
      Predictions[_id].state == State.Concluded,
      "Prediction not concluded"
    );
    require(
      Purchases[msg.sender][_id].purchased == true,
      "No purchase history found"
    );
    require(Purchases[msg.sender][_id].refunded == false, "Already refunded");
    require(
      Predictions[_id].winningClosingVote == ValidationStatus.Negative,
      "Prediction won"
    );
    Balances[msg.sender] += Predictions[_id].price;
    Purchases[msg.sender][_id].refunded = true;
    emit BuyerRefunded(msg.sender, _id, Predictions[_id].price);
  }

  function settleSeller(uint256 _id) external onlySeller(_id) {
    require(
      Predictions[_id].state == State.Concluded,
      "Prediction not concluded"
    );
    require(Predictions[_id].withdrawnEarnings == false, "Earnings withdrawn");

    require(Predictions[_id].winningClosingVote == ValidationStatus.Positive, "Prediction lost!");

     
      uint256 _minerEarnings = (Predictions[_id].price *
        PredictionStats[_id].buyCount *
        minerPercentage) / 100;
      uint256 _totalMinersRewards = _minerEarnings *
        PredictionStats[_id].validatorCount;
      uint256 _sellerEarnings =
        (Predictions[_id].price * PredictionStats[_id].buyCount) -
        _totalMinersRewards;
   
    Predictions[_id].withdrawnEarnings = true;
    Balances[Predictions[_id].seller] += _sellerEarnings;
    emit SellerSettled(msg.sender, _id, _sellerEarnings);
  }

  

  ///@dev Withdraw funds from the contract
  ///@param _amount Amount to be withdrawn

  function withdrawFunds(uint256 _amount) external isOpen {
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

  ///@dev Withdraw locked funds to contract balance.
  ///@param _amount Amount to be withdrawn

  function transferLockedFunds(uint256 _amount) external {
    require(LockedFunds[msg.sender].amount >= _amount, "Not enough balance");
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

  function addProfile(string memory _profileData, string memory _key) external {
    User[msg.sender].profile = _profileData;
    User[msg.sender].key = _key;
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
  }







  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath:multiplication overflow");
    return c;
  }

  ///@dev checks if prediction data meets requirements
  /// @param _startTime Timestamp of the kickoff time of the first prediction event
  /// @param _endTime Timestamp of the proposed end of the last prediction event
  ///@return bool

  function _sellerDoesMeetMinimumRequirements(
    uint256 _startTime,
    uint256 _endTime
  ) internal view returns (bool) {
    require(_endTime > _startTime, "End time less than start time");
    if (
      add(block.timestamp, mul(8, HOURS)) > _startTime ||
      _startTime > add(block.timestamp, mul(24, HOURS)) ||
      sub(_endTime, _startTime) > mul(24, HOURS)
    ) {
      return false;
    }

    return true;
  }

  function getMiningPoolLength() public view returns (uint256 length) {
    return miningPool.length;
  }

  function getActivePoolLength() public view returns (uint256 length) {
    return activePool.length;
  }

  function getOwnedPredictionsLength(address seller)
    public
    view
    returns (uint256 length)
  {
    return OwnedPredictions[seller].length;
  }

  function getOwnedValidationsLength(address miner)
    public
    view
    returns (uint256 length)
  {
    return OwnedValidations[miner].length;
  }

  function getBoughtPredictionsLength(address buyer)
    public
    view
    returns (uint256 length)
  {
    return BoughtPredictions[buyer].length;
  }

  function getRecentPrediction(address seller, uint8 index) public view returns(uint256) {
    return User[seller].last30Predictions[index];
  }


}
