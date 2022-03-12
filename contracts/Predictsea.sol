// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// @title PredictSea {Blockchain powered sport prediction marketplace}

contract Main {
    address payable public owner;   //The contract deployer and owner

   /**
   maps unique id of prediction in the centralized server
   to each contract struct record.
    */
    mapping(uint256 =>  PredictionData) internal Predictions; 

    mapping(address => uint256) public Balances;

    address public constant NFT_CONTRACT_ADDRESS = address(0); //to be changed

    uint private constant SIXTY_PERCENT = 3;

    uint private constant EIGHTY_PERCENT = 4;

    uint private constant MAX_VALIDATORS = 5;

    uint private constant TO_PERCENTAGE = 100;

    uint private constant BANK_ROLL = 1000;

    uint private constant CONSTANT_VALUE_MULTIPLIER = 1000;

    uint private constant SIX_HOURS = 21600;

    uint private constant TWELVE_HOURS = 43200;

    uint private constant TWENTY_FOUR_HOURS = 86400;


    mapping(address => uint256[]) public OwnedPredictions; 

    mapping (uint256 => address) internal TokenOwner;

    mapping(address => ValidationData[]) public OwnedValidations;
     

  /** users can have thier accounts verified by 
  purchasing a unique username mapped to thier address */
    mapping(bytes32 => address) public UsernameService;

    mapping(address => Profile) public UserProfile;

    /** contract can be locked in case of emergencies */
    bool public locked = false;


    uint256 private lastLockedDate;

    /** nominated address can claim ownership of contract 
    and automatically become owner */
    address payable private nominatedOwner;

    enum Status {
        Pending,
        Complete,
        Won,
        Lost,
        Inconclusive
    }

    enum State {
      Inactive,
      Withdrawn,
      Denied,
      Active,
      Concluded
    }

    enum ValidationStatus {
      Neutral,
      Assigned,
      Positive,
      Negative
    }

    struct Vote {
      ValidationStatus opening;
      ValidationStatus closing;
      bool stakingFeeRefunded;
      bool correctValidation;
    }

    struct PredictionData {
        uint256 UID; // reference to database prediction record
        address seller;
        uint256 startTime; //start time of first predicted event
        uint256 endTime; //start time of last predicted event
        uint16 odd;
        uint256 price;
        address[] buyersList;
        mapping(address => bool) buyers; 
        mapping(uint256 => Vote) validators; //maps miners tokenId to vote data 
        uint8 validatorCount;
        uint8 positiveOpeningVoteCount;
        uint8 negativeOpeningVoteCount;
        uint8 positiveClosingVoteCount;
        uint8 negativeClosingVoteCount;
        uint64 buyCount; // total count of purchases
        Status status;
        State state;
        uint256 totalEarned;
        bool sellerStakingFeeRefunded;
        bool withdrawnEarnings;
    }

    struct ValidationData {
      uint256 tokenId;
      uint256 UID;
    }

    struct PredictionHistory {
      uint32 odd;
      uint256 winnings;
    }

    struct Profile {
        bytes32 username; 
        uint16 rating;
        uint256 wonCount;
        uint256 lostCount;
        uint256 totalPredictions;
        uint256  totalOdds;
        uint256 grossWinnings;
        PredictionHistory[] last30Predictions;

        //Remember to divide by constant value (1000)

        uint256 recentWinRate;
        int256 recentYield;
        int256 recentROI;
        int256 recentProfitablity;
        uint256 recentAverageOdds;

        uint256 lifetimeWinRate;
        int256 lifetimeYield;
        int256 lifetimeROI;
        int256 lifetimeProfitability;
        uint256 lifetimeAverageOdds;
    }

    uint256 public miningFee; // paid by seller -> to be shared by validators
    uint256 public sellerStakingFee; // paid by seller, staked per prediction
    uint256 public minerStakingFee; // paid by miner, staked per validation
    uint32 public minerPercentage; // % commission for miner, In event of a prediction won
    uint32 public sellerPercentage; // % sellers cut, In event of prediction won
    uint32 public minimumOdd; 
    uint256 public minimumPrice;
    uint16 public minimumVerificationPredictionsCount;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    /**********************************/

    event PredictionCreated(
      address sender, 
      uint256 UID, 
      uint256 startTime, 
      uint256 endTime,
      uint16 odd,
      uint256 price
      );
    event DepositCreated(address sender, uint256 value);
    event IsLocked(bool lock_status);
    event NewOwnerNominated(address nominee);
    event OwnershipTransferred(address newOwner);

    /**Validator opening events (Arch 2) *temp */

    event ValidationRequested();
    event VoteSubmitted();
    event PredictionPurchased(bytes32 email);
    event ClosingVoteSubmitted();
    event PredictionWithdrawn();
    event PredictionUpdated();
    event MinerOpeningVoteUpdated();
    event MinerClosingVoteUpdated();
    event UsernameCreated(address, bytes32);
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access to contract");
        _;
    }

    modifier isOpen(){
      require(!locked, "Contract in locked state");

      _;
    }


    modifier uniqueId(uint256 UID){
      require(Predictions[UID].UID == 0 , "UID already exists");
      _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier onlySeller(uint256 _UID){
      require(msg.sender == Predictions[_UID].seller, "Only prediction seller");
      _;
    }

    modifier notSeller(uint256 _UID){
      require(msg.sender != Predictions[_UID].seller, "Seller Unauthorized!");
      _;
    }

    modifier predictionMeetsMinimumRequirements(
      uint256 _startTime, 
      uint256 _endTime, 
      uint16 _odd, 
      uint256 _price
      ){ 
        
        require(_sellerDoesMeetMinimumRequirements(
          _startTime, _endTime, _odd, _price),
          "Doesn't meet min requirements"
          );

        _;
       
    }
  
    modifier hasMinimumBalance(uint256 _amount){
      require(Balances[msg.sender] >= _amount, "Not enough balance");

      _;
    }



    /**Validator opening modifier (Arch 2) *temp */

    modifier predictionEventNotStarted(uint256 _UID){
     require(Predictions[_UID].startTime > block.timestamp, "Event already started");
      _;
    }

    modifier validatorCountIncomplete(uint256 _UID){
      require(Predictions[_UID].validatorCount < MAX_VALIDATORS, "Required validator limit reached");
      _;
    }

    modifier validatorCountComplete(uint256 _UID){
      require(Predictions[_UID].validatorCount == MAX_VALIDATORS, "Required validator limit reached");
      _;
    }

    modifier newValidationRequest(uint256 _UID, uint256 _tokenId){
      require(Predictions[_UID].validators[_tokenId].opening == ValidationStatus.Neutral,
       "Invalid validation request");
      _;
    }

    modifier predictionActive(uint256 _UID){
      require(Predictions[_UID].state == State.Active, "Prediction currently inactive");
      _;
    }

    modifier notMined(uint256 _UID){
       require(Predictions[_UID].validatorCount == 0, "Prediction already mined");
       _;
    }

    modifier isNftOwner(uint256 _tokenId){
      require(TokenOwner[_tokenId] == msg.sender,  "Not NFT Owner");
      _;
    }
    

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/

    // constructor
    constructor(
        uint256 _miningFee,
        uint256 _sellerStakingFee,
        uint256 _minerStakingFee,
        uint32 _minerPercentage,
        uint32 _sellerPercentage,
        uint16 _minimumOdd,
        uint256 _minimumPrice,
        uint16 _minimumVerificationPredictionsCount
    ) {
        owner = payable(msg.sender);
        miningFee = _miningFee;
        sellerStakingFee = _sellerStakingFee;
        minerStakingFee = _minerStakingFee;
        minerPercentage =  _minerPercentage;
        sellerPercentage = _sellerPercentage;
        minimumOdd = _minimumOdd;
        minimumPrice = _minimumPrice;
        minimumVerificationPredictionsCount = _minimumVerificationPredictionsCount;
    }
    /** Does new prediction data satisfy all minimum requirements */
    function _sellerDoesMeetMinimumRequirements(
      uint256 _starttime, 
      uint256 _endtime, 
      uint16 _odd, 
      uint256 _price
      ) internal view returns(bool) {

      if(_starttime  < block.timestamp || 
        _endtime < block.timestamp ||
        _endtime < _starttime ||
        (_endtime - _starttime) > TWENTY_FOUR_HOURS){

        return false;
      }

      if(_odd < minimumOdd || _price < minimumPrice){
        return false;
      }

      return true;
    }

    function _setupPrediction(
      uint256 _UID, 
      uint256 _startTime, 
      uint256 _endTime, 
      uint16 _odd, 
      uint256 _price
      ) internal uniqueId(_UID) predictionMeetsMinimumRequirements(
      _startTime, 
      _endTime, 
      _odd, 
     _price
      )   {
       
       Predictions[_UID].UID = _UID;
       Predictions[_UID].seller = msg.sender;
       Predictions[_UID].startTime = _startTime;
       Predictions[_UID].endTime = _endTime;
       Predictions[_UID].odd = _odd;
       Predictions[_UID].price = _price;

       OwnedPredictions[msg.sender].push(_UID);
      }

    function createPredictionWithWallet(
      uint256 _UID, 
      uint256 _startTime, 
      uint256 _endTime, 
      uint16 _odd, 
      uint256 _price
      )  external  {
      uint256 total = miningFee + sellerStakingFee;
      require(Balances[msg.sender]>= total, "Not enough balance");
      Balances[msg.sender] -= total;

      _setupPrediction(_UID, _startTime, _endTime, _odd, _price);
      emit PredictionCreated(msg.sender, _UID, _startTime, _endTime, _odd, _price);
    }

    function createPrediction(
      uint256 _UID, 
      uint256 _startTime, 
      uint256 _endTime, 
      uint16 _odd, 
      uint256 _price
      ) external payable {
      uint256 total = miningFee + sellerStakingFee;
      require(msg.value >= total, "Not enough ether");
      uint256 bal = msg.value - total;
      if(bal > 0){
        Balances[msg.sender] += bal;
      }

       _setupPrediction(_UID, _startTime, _endTime, _odd, _price);
      emit PredictionCreated(msg.sender, _UID, _startTime, _endTime, _odd, _price);
    }




     /**Validator opening methods (Arch 2) (to be moved) */

    /*╔══════════════════════════════╗
      ║  TRANSFER NFT TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    function _transferNftToContract(uint256 _tokenId) internal {
      
        if (IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender) {
            IERC721(NFT_CONTRACT_ADDRESS).transferFrom(
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

    function _setUpValidationRequest(uint256 _tokenId, uint256 _UID) internal 
    validatorCountIncomplete(_UID)
    predictionEventNotStarted(_UID)
    newValidationRequest(_UID, _tokenId)
    {
      require(Predictions[_UID].state != State.Withdrawn, "Prediction Withdrawn");
      Predictions[_UID].validators[_tokenId].opening = ValidationStatus.Assigned;
      Predictions[_UID].validators[_tokenId].closing = ValidationStatus.Assigned;
      Predictions[_UID].validatorCount += 1;
      if(Predictions[_UID].validatorCount == MAX_VALIDATORS){
        Predictions[_UID].status = Status.Complete;
      }
      ValidationData memory _data = ValidationData({tokenId:_tokenId, UID:_UID});
      OwnedValidations[msg.sender].push(_data);
    }

    function requestValidationWithWallet(uint256 _tokenId, uint256 _UID) external 
    
    {
      require(Balances[msg.sender] >= minerStakingFee, "Not enough balance");
      Balances[msg.sender] -= minerStakingFee;
      _transferNftToContract(_tokenId);
      _setUpValidationRequest(_tokenId, _UID);
      emit ValidationRequested(); 
    }

    function requestValidation(uint256 _tokenId, uint256 _UID)  external payable 
    {
      require(msg.value >= minerStakingFee, "Not enough balance");
      _transferNftToContract(_tokenId);
      _setUpValidationRequest(_tokenId, _UID);
      emit ValidationRequested(); 
    }

    function _setUpOpeningVote(uint256 _UID, uint256 _tokenId) internal isNftOwner(_UID)
     view returns(Vote storage) {
      
      require(Predictions[_UID].validators[_tokenId].opening == ValidationStatus.Assigned,
       "Vote already cast!");
      require(Predictions[_UID].startTime > block.timestamp, "Event already started");
      return Predictions[_UID].validators[_tokenId];
     
    }

    function submitOpeningVote(uint256 _UID, uint256 _tokenId, uint8 _option) external  
    {
      require(_option == 1 || _option == 2, "Invalid validation option");

      Vote storage _vote = _setUpOpeningVote(_UID, _tokenId);
       if(_option == 1){
        _vote.opening = ValidationStatus.Positive;
        Predictions[_UID].positiveOpeningVoteCount += 1;
      }else{
        _vote.opening = ValidationStatus.Negative;
        Predictions[_UID].negativeOpeningVoteCount += 1;
      }

      if(Predictions[_UID].positiveOpeningVoteCount == SIXTY_PERCENT){
        //prediction receives 60% positive validations
        Predictions[_UID].state = State.Active;
        
      }
      if(Predictions[_UID].negativeOpeningVoteCount >= EIGHTY_PERCENT){
        Predictions[_UID].state = State.Denied;
      }
      
      uint256 minerBonus = miningFee / MAX_VALIDATORS; 
      Balances[msg.sender] += minerBonus; //miner recieves mining bonus.

      emit VoteSubmitted();

    }

    /** Buyer architecture implementation, (To be moved) */

    function _setUpPurchase(uint256 _UID) internal 
    predictionEventNotStarted(_UID)
    predictionActive(_UID){
      Predictions[_UID].buyers[msg.sender] = true;
      Predictions[_UID].buyersList.push(msg.sender);
      Predictions[_UID].buyCount += 1;
      Predictions[_UID].totalEarned += Predictions[_UID].price;
    }

    function purchasePredictionWithWallet(bytes32 email, uint256 _UID) external{
      PredictionData storage _prediction = Predictions[_UID];
      require(Balances[msg.sender] >= _prediction.price, "Insufficient balance");
      Balances[msg.sender] -= _prediction.price;
      _setUpPurchase(_UID);
      emit PredictionPurchased(email);

    }

    function purchasePrediction(bytes32 email, uint256 _UID) external payable {
      PredictionData storage _prediction = Predictions[_UID];
      require(msg.value >= _prediction.price, "Not enough ether");
      _setUpPurchase(_UID);
      emit PredictionPurchased(email);
    }


    /** Miner closing architecture (4) */

    function _setUpClosingVote(uint256 _UID, uint256 _tokenId) internal
     view returns(Vote storage) {
      require(TokenOwner[_tokenId] == msg.sender,  "Not NFT Owner");
      require(Predictions[_UID].validators[_tokenId].opening == ValidationStatus.Positive ||
      Predictions[_UID].validators[_tokenId].opening == ValidationStatus.Negative,
       "Vote already cast!");
       require(Predictions[_UID].validators[_tokenId].closing == ValidationStatus.Assigned,
       "Vote already cast!"
       );
      /**Cool down period is 6hrs (21600 secs) after the game ends */
      require((block.timestamp > Predictions[_UID].endTime + SIX_HOURS && 
      block.timestamp < Predictions[_UID].endTime + TWELVE_HOURS), "Event not cooled down");
      return Predictions[_UID].validators[_tokenId];
      
    }

    function submitClosingVote(uint256 _UID, uint256 _tokenId, uint8 _option) external {
      require(_option == 1 || _option == 2, "Invalid validation option");

      Vote storage _vote = _setUpClosingVote(_UID, _tokenId);
       if(_option == 1){
        _vote.closing = ValidationStatus.Positive;
        Predictions[_UID].positiveOpeningVoteCount += 1;
      }else{
        _vote.closing = ValidationStatus.Negative;
        Predictions[_UID].negativeOpeningVoteCount += 1;
      }
      emit ClosingVoteSubmitted();

    }


    function _getNftIndex(ValidationData[] memory _validations, uint256 _tokenId) internal pure returns(bool, uint256) {
      bool found;
      uint256 position;
      for (uint256 index = 0; index < _validations.length; index++) {
        position = index;
        if(_validations[index].tokenId == _tokenId){
          found = true;
          break;
           
        }
        
      }
      return (found, position);
    }



    function withdrawNFT(uint256 _tokenId) internal {
      require(TokenOwner[_tokenId] == msg.sender,  "Not NFT Owner");
      address _nftRecipient = TokenOwner[_tokenId];
      IERC721(NFT_CONTRACT_ADDRESS).transferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
      require(
                IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender,
                "nft transfer failed"
            );
       
      
    }

    function _removeFromOwnedPredictions(uint256[] storage _activePredictions, uint256 _UID)
          internal{
            if(_activePredictions.length == 0){
              return;
            }else if(_activePredictions.length == 1){
              _activePredictions.pop();
              return;
            }else{
              uint position;
              for (uint256 index = 0; index < _activePredictions.length; index++) {

                if(_activePredictions[index] == _UID){
                  position = index;
                  break;
            }
               }
               if(position > 0){
                  for (uint i = position; i < _activePredictions.length - 1; i++) {
                _activePredictions[i] = _activePredictions[i + 1];
            }
            _activePredictions.pop();
               }
       }
           
          
    }


    function concludeTransaction(uint256 _UID) external {
      PredictionData storage _prediction = Predictions[_UID];
      require(!_prediction.withdrawnEarnings, "Transaction already concluded");
      _setUpSellerClosing(_prediction);
      if(_prediction.status == Status.Won){
        uint256 _sellerPercentageAmount = _prediction.totalEarned * (sellerPercentage / 100);
        Balances[_prediction.seller] += _sellerPercentageAmount;
      }else{
        for (uint256 index = 0; index < _prediction.buyersList.length; index++) {
          Balances[_prediction.buyersList[index]] += _prediction.price;
        }
      }
        _removeFromOwnedPredictions(OwnedPredictions[_prediction.seller], Predictions[_UID].UID);
        _prediction.withdrawnEarnings = true;     
    }


    function _updateSellerProfile(PredictionData storage _prediction, bool _predictionWon) internal {
      UserProfile[_prediction.seller].totalPredictions += 1;
      UserProfile[_prediction.seller].totalOdds += _prediction.odd;
      if(_predictionWon){
        UserProfile[_prediction.seller].wonCount += 1;
        UserProfile[_prediction.seller].grossWinnings += BANK_ROLL * _prediction.odd;
      }else{
        UserProfile[_prediction.seller].lostCount += 1;
      }
      _addToRecentPredictionsList(_prediction.seller, _prediction.odd, _predictionWon);
      uint256 _listLength = (UserProfile[_prediction.seller].last30Predictions).length;
      ( uint256 _wonCount,
      uint256 _grossWinnings, 
      uint256 _moneyLost, 
      uint256 _totalOdds ) = _getRecentPredictionsData(_prediction.seller);
      UserProfile[_prediction.seller].recentWinRate = _getRecentWinRate(
        _wonCount,
        _listLength
      );
      UserProfile[_prediction.seller].recentYield = _getRecentYield(
        _grossWinnings,
        _listLength
      );
      UserProfile[_prediction.seller].recentROI = _getRecentROI(
        _grossWinnings,
        _listLength
      );
      UserProfile[_prediction.seller].recentProfitablity = _getRecentProfitability(
        _grossWinnings, 
        _moneyLost,
        _listLength
      );
      UserProfile[_prediction.seller].recentAverageOdds = _getRecentAverageOdds(
        _totalOdds,
        _listLength
      );

      UserProfile[_prediction.seller].lifetimeWinRate = _getLifetimeWinRate(_prediction.seller);
      UserProfile[_prediction.seller].lifetimeYield = _getLifetimeYield(_prediction.seller);
      UserProfile[_prediction.seller].lifetimeROI = _getLifetimeROI(_prediction.seller);
      UserProfile[_prediction.seller].lifetimeProfitability = _getLifetimeProfitability(_prediction.seller);
      UserProfile[_prediction.seller].lifetimeAverageOdds = _getLifetimeAverageOdds(_prediction.seller);
    }

    function _refundSellerStakingFee(PredictionData storage _prediction) internal {
     
      if(_prediction.state != State.Denied &&
          !_prediction.sellerStakingFeeRefunded ){
             _prediction.sellerStakingFeeRefunded = true;
                Balances[_prediction.seller] += sellerStakingFee;
          }
     
    }

  

    function _setPredictionOutcome(PredictionData storage _prediction) internal {
      if(_prediction.positiveClosingVoteCount > 
      _prediction.negativeClosingVoteCount){
        _prediction.status = Status.Won;
      }else if(_prediction.positiveClosingVoteCount < 
      _prediction.negativeClosingVoteCount){
        _prediction.status = Status.Lost;
      }else{
        _prediction.status = Status.Inconclusive;
      }
    }

   function _setUpSellerClosing(PredictionData storage _prediction) internal {
     require(_prediction.seller == msg.sender, "Not seller");
     require(_prediction.state == State.Active, "Event no longer active");
     require(block.timestamp > _prediction.endTime + SIX_HOURS, "Event not cooled down");
       _refundSellerStakingFee(_prediction);
      _setPredictionOutcome(_prediction);
      _prediction.state = State.Concluded;
      bool _outcome = _prediction.status == Status.Won ? true : false;
      _updateSellerProfile(_prediction, _outcome);
   }

   /**pheripheral functions */
  function withdrawPrediction(uint256 _UID) external 
  onlySeller(_UID) notMined(_UID) {
    PredictionData storage _prediction = Predictions[_UID];
   _refundSellerStakingFee(_prediction);
    _prediction.state = State.Withdrawn;

    emit PredictionWithdrawn();

  }

  function updatePrediction(
      uint256 _UID, 
      uint256 _startTime, 
      uint256 _endTime, 
      uint16 _odd, 
      uint256 _price
      ) external onlySeller(_UID) notMined(_UID) {
    _setupPrediction(_UID, _startTime, _endTime, _odd, _price);

    emit PredictionUpdated();
  }

  function _getMinerOpeningPredictionVote(uint256 _UID, uint256 _tokenId) internal view
  returns(ValidationStatus){
    return Predictions[_UID].validators[_tokenId].opening;
  }

  function _getMinerClosingPredictionVote(uint256 _UID, uint256 _tokenId) internal view 
  returns(ValidationStatus) {
    return Predictions[_UID].validators[_tokenId].closing;
  }



  function updateMinerOpeningVote(uint256 _UID, uint256 _tokenId, uint8 _vote) external isNftOwner(_tokenId){
    require(Predictions[_UID].state == State.Inactive, "Prediction already active");
    ValidationStatus _status = _getMinerOpeningPredictionVote(_UID, _tokenId);
    require(_status != ValidationStatus.Neutral && _status != ValidationStatus.Assigned , "Didn't vote previously");
    require(_vote > 1 && _vote <= 3, "Vote cannot be neutral");
    if(_vote == 2){
      require(_status != ValidationStatus.Positive, "same as previous vote option");
      Predictions[_UID].validators[_tokenId].opening = ValidationStatus.Positive;
      Predictions[_UID].negativeOpeningVoteCount -= 1;
      Predictions[_UID].positiveOpeningVoteCount += 1;
    }else{
      require(_status != ValidationStatus.Negative, "same as previous vote option");
      Predictions[_UID].validators[_tokenId].opening = ValidationStatus.Negative;
       Predictions[_UID].positiveOpeningVoteCount -= 1;
       Predictions[_UID].negativeOpeningVoteCount += 1;
    }

    if(Predictions[_UID].positiveOpeningVoteCount == SIXTY_PERCENT){
        //prediction receives 60% positive validations
        Predictions[_UID].state = State.Active;
      }
      emit MinerOpeningVoteUpdated();
  }

  function updateMinerClosingVote(uint256 _UID, uint256 _tokenId, uint8 _vote) external isNftOwner(_tokenId){
    require(Predictions[_UID].validators[_tokenId].closing == ValidationStatus.Positive ||
    Predictions[_UID].validators[_tokenId].closing == ValidationStatus.Negative,
       "Closing vote not cast yet!"
       );
      /**Cool down period is 6hrs (21600 secs) after the game ends */
      require((block.timestamp > Predictions[_UID].endTime + SIX_HOURS && 
      block.timestamp < Predictions[_UID].endTime + TWELVE_HOURS), "Event not cooled down");

      require(_vote > 1 && _vote <= 3, "Vote cannot be neutral");
      ValidationStatus _status = _getMinerClosingPredictionVote(_UID, _tokenId);
      if(_vote == 2){
      require(_status != ValidationStatus.Positive, "same as previous vote option");
      Predictions[_UID].validators[_tokenId].closing = ValidationStatus.Positive;
      Predictions[_UID].negativeClosingVoteCount -= 1;
      Predictions[_UID].positiveClosingVoteCount += 1;
        }else{
      require(_status != ValidationStatus.Negative, "same as previous vote option");
      Predictions[_UID].validators[_tokenId].closing = ValidationStatus.Negative;
       Predictions[_UID].positiveClosingVoteCount -= 1;
       Predictions[_UID].negativeClosingVoteCount += 1;
    }

    emit MinerClosingVoteUpdated();
  }

   function ownerOfNft(uint256 _tokenId) external view returns(address){
     return TokenOwner[_tokenId];
   }

   function withdrawFunds(uint256 _amount) external {
     require(Balances[msg.sender] >= _amount, "Not enough balance");
     Balances[msg.sender] -= _amount;
     // attempt to send the funds to the recipient
            (bool success, ) = payable(msg.sender).call{
                value: _amount,
                gas: 23000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                Balances[msg.sender] += _amount;
                   
            }
   }

   function createUsername(bytes32 _username) external {
     require(UserProfile[msg.sender].totalPredictions >= minimumVerificationPredictionsCount,
     "Not enough total predictions");
     require(_username != bytes32(0), "Username cannot be null");
     require(UserProfile[msg.sender].username == bytes32(0), "Username already exists");
     UserProfile[msg.sender].username = _username;
     emit UsernameCreated(msg.sender, _username);
   }

   function _getLifetimeWinRate(address _tipster) internal view returns(uint256) {
     return ((UserProfile[_tipster].wonCount * CONSTANT_VALUE_MULTIPLIER) / 
     UserProfile[_tipster].totalPredictions) * TO_PERCENTAGE;
   }

   function _getLifetimeYield(address _tipster) internal view returns(int256) {
     int256 _grossWinings = int(UserProfile[_tipster].grossWinnings);
     int256 _capitalEmployed = int(UserProfile[_tipster].totalPredictions) * int(BANK_ROLL);
     
     return (((_grossWinings - _capitalEmployed) * int(CONSTANT_VALUE_MULTIPLIER)) 
            / _capitalEmployed) * int(TO_PERCENTAGE);
     
   }

   function _getLifetimeROI(address _tipster) internal view returns(int256){
     int256 _grossWinings = int(UserProfile[_tipster].grossWinnings);
     int256 _capitalEmployed = int(UserProfile[_tipster].totalPredictions) * int(BANK_ROLL);

     return ((_grossWinings - _capitalEmployed) * int(CONSTANT_VALUE_MULTIPLIER)) 
           / int(BANK_ROLL) * int(TO_PERCENTAGE);
   }

   function _getLifetimeProfitability(address _tipster) internal view returns(int256){
     int256 _grossWinings = int(UserProfile[_tipster].grossWinnings);
     int256 _capitalEmployed = int(UserProfile[_tipster].totalPredictions) * int(BANK_ROLL);
     int256 _moneyLost = int(BANK_ROLL) * int(UserProfile[_tipster].lostCount);

     return ((_grossWinings - _capitalEmployed)
      * int(CONSTANT_VALUE_MULTIPLIER)) 
      / _moneyLost * int(TO_PERCENTAGE);
     
   }

   function _getLifetimeAverageOdds(address _tipster) internal view returns (uint256) {
      return (UserProfile[_tipster].totalOdds * CONSTANT_VALUE_MULTIPLIER) / 
      UserProfile[_tipster].totalPredictions;
   }

   function _addToRecentPredictionsList(address _tipster, uint32 _odd, bool _won) internal {
     PredictionHistory[] storage _list = UserProfile[_tipster].last30Predictions;
     uint256 _winnings = _won ? (uint(BANK_ROLL) * _odd) : 0;
     if(_list.length < 30){
       _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
     }else{
       for (uint i = 0; i < _list.length - 1; i++) {
            _list[i] = _list[i + 1];
        }
        _list.pop();
        _list.push(PredictionHistory({odd: _odd, winnings: _winnings}));
     }
   }

   function _getRecentWinRate(
     uint256 _wonCount,
     uint256 listLength
     ) internal pure returns (uint256) {
      return (_wonCount * CONSTANT_VALUE_MULTIPLIER) / listLength * TO_PERCENTAGE;
   }

   function _getRecentYield(
     uint256 _grossWinnings,
     uint256 listLength
     ) internal pure returns(int256) {

     uint256 _capitalEmployed = listLength * BANK_ROLL;
     return ((int(_grossWinnings) - int(_capitalEmployed))
      * int(CONSTANT_VALUE_MULTIPLIER)) / (int(_capitalEmployed) * int(TO_PERCENTAGE));
     
   }

   function _getRecentROI(
     uint256 _grossWinnings,
     uint256 listLength
     ) internal pure returns(int256) {
     
     uint256 _capitalEmployed = listLength * BANK_ROLL;

     return ((int(_grossWinnings) - int(_capitalEmployed)) * int(CONSTANT_VALUE_MULTIPLIER))
       / int(BANK_ROLL) * int(TO_PERCENTAGE);

   }

   function _getRecentProfitability(
     uint256 _grossWinnings,
     uint256 _moneyLost,
     uint256 listLength
   ) internal pure returns(int256) {
     uint256 _capitalEmployed = listLength * BANK_ROLL;
    
     return ((int(_grossWinnings) - int(_capitalEmployed))
      * int(CONSTANT_VALUE_MULTIPLIER))  /  int(_moneyLost) * int(TO_PERCENTAGE);
   }

   function _getRecentAverageOdds( 
     uint256 _totalOdds,
     uint256 listLength
     )
    internal pure returns (uint256) {
      return (_totalOdds * CONSTANT_VALUE_MULTIPLIER) / listLength;
   }

   function _getRecentPredictionsData(address _tipster) internal view 
   returns(
     uint256 _wonCount,
     uint256 _grossWinnings,
     uint256 _moneyLost,
     uint256 _totalOdds
     ){

     PredictionHistory[] memory _list = UserProfile[_tipster].last30Predictions;
   
      for (uint256 index = 0; index < _list.length; index++) {
        if(_list[index].winnings != 0){
          _wonCount += 1;
        }
        _grossWinnings += _list[index].winnings;
        _moneyLost += _list[index].winnings == 0 ? BANK_ROLL : 0;
         _totalOdds += _list[index].odd;

      }
      return(_wonCount, _grossWinnings, _moneyLost, _totalOdds);
   }

  /** GENERAL ACCESS FUNCTIONS (to be moved) */

    receive() external payable {
      Balances[msg.sender] += msg.value;
      emit DepositCreated(msg.sender, msg.value);
    }

    function lock() external onlyOwner {
      locked = true;
      lastLockedDate = block.timestamp;
      emit IsLocked(locked);
    } 

    function unlock() external {
      require(locked && (msg.sender == owner || (block.timestamp >  lastLockedDate + 604800)),
      "Not owner!");
      locked = false;
      emit IsLocked(locked);
    }

    function nominateNewOwner(address _address) external onlyOwner notZeroAddress(_address) {
      require(_address != owner, "Owner address can't be nominated");
      nominatedOwner = payable(_address);
      emit NewOwnerNominated(nominatedOwner);
    }

    function transferOwnership() external {
      require(nominatedOwner != address(0), "Nominated owner not set");
      require(msg.sender == nominatedOwner, "Not a nominated owner");
      owner = nominatedOwner;
      emit OwnershipTransferred(owner);
    }

}
