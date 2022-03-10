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

    mapping(address => uint256[]) public OwnedPredictions; //to change to array of struct


    mapping (uint256 => address) internal TokenOwner;

    mapping(address => ValidationData[]) public OwnedValidations;
     

  /** users can have thier accounts verified by 
  purchasing a unique username mapped to thier address */
    mapping(address => bytes32) public UsernameService;

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

    struct Profile { 
        uint8 rating;
        uint256 wonCount;
        uint256 lostCount;
        uint256 totalPredictions;
    }

    uint256 public miningFee; // paid by seller -> to be shared by validators
    uint256 public sellerStakingFee; // paid by seller, staked per prediction
    uint256 public minerStakingFee; // paid by miner, staked per validation
    uint32 public minerPercentage; // % commission for miner, In event of a prediction won
    uint32 public sellerPercentage; // % sellers cut, In event of prediction won
    uint32 public minimumOdd; 
    uint256 public minimumPrice;

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
      require(Predictions[_UID].validatorCount < 5, "Required validator limit reached");
      _;
    }

    modifier validatorCountComplete(uint256 _UID){
      require(Predictions[_UID].validatorCount == 5, "Required validator limit reached");
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
        uint256 _minimumPrice
    ) {
        owner = payable(msg.sender);
        miningFee = _miningFee;
        sellerStakingFee = _sellerStakingFee;
        minerStakingFee = _minerStakingFee;
        minerPercentage =  _minerPercentage;
        sellerPercentage = _sellerPercentage;
        minimumOdd = _minimumOdd;
        minimumPrice = _minimumPrice;
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
        (_endtime - _starttime) > 86400){

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
       PredictionData storage _prediction = Predictions[_UID];
       _prediction.UID = _UID;
       _prediction.seller = msg.sender;
       _prediction.startTime = _startTime;
       _prediction.endTime = _endTime;
       _prediction.odd = _odd;
       _prediction.price = _price;

      

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
       OwnedPredictions[msg.sender].push(_UID);
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
        OwnedPredictions[msg.sender].push(_UID);
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
      if(Predictions[_UID].validatorCount == 5){
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

      if(Predictions[_UID].positiveOpeningVoteCount == 3){
        //prediction receives 60% positive validations
        Predictions[_UID].state = State.Active;
        UserProfile[Predictions[_UID].seller].totalPredictions += 1;
      }
      if(Predictions[_UID].negativeOpeningVoteCount >= 4){
        Predictions[_UID].state = State.Denied;
      }
      
      uint256 minerBonus = miningFee / 5; 
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
      require((block.timestamp > Predictions[_UID].endTime + 21600 && 
      block.timestamp < Predictions[_UID].endTime + 43200), "Event not cooled down");
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

    function withdrawNFT(uint256 _tokenId) external {
      require(TokenOwner[_tokenId] == msg.sender,  "Not NFT Owner");
      ValidationData[] memory _validations = OwnedValidations[msg.sender];
      (bool found, uint256 position) = _getNftIndex(_validations, _tokenId);
      require(found, "NFT not found!");
      uint256 _UID = _validations[position].UID;
      uint256 _superCoolDownTime = Predictions[_UID].endTime + 43200;
      require(Predictions[_UID].state == State.Concluded ||
       block.timestamp > _superCoolDownTime,
       "Cannot withdraw NFT now");
        _settleValidator(_UID, _tokenId);
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

    function _settleValidator(uint256 _UID, uint256 _tokenId) internal {
      require(TokenOwner[_tokenId] == msg.sender, "Not token owner");
      Vote memory _vote = Predictions[_UID].validators[_tokenId];
      require(_vote.opening == ValidationStatus.Positive ||
      _vote.opening == ValidationStatus.Negative, "Didn't vote on opening");
      Status _status = Predictions[_UID].status;
      if(_status == Status.Won){
        
      }
      
      
    }



    function _settleSeller(uint256 _UID) internal {
      PredictionData storage _prediction = Predictions[_UID];
      require(!_prediction.withdrawnEarnings, "Earnings already withdrawn");
      if(_prediction.status == Status.Won){
        _refundSellerStakingFee(_UID);
        uint256 _sellerPercentageAmount = _prediction.totalEarned * (sellerPercentage / 100);
        Balances[_prediction.seller] += _sellerPercentageAmount;
      }else{
        for (uint256 index = 0; index < _prediction.buyersList.length; index++) {
          Balances[_prediction.buyersList[index]] += _prediction.price;
        }
      }

      _prediction.withdrawnEarnings = true;
    }

    function _refundSellerStakingFee(uint _UID) internal {
      address seller = Predictions[_UID].seller;
      require(Predictions[_UID].state != State.Denied, "Refund request denied");
      require(!Predictions[_UID].sellerStakingFeeRefunded, "Staking fee already refunded");
      Predictions[_UID].sellerStakingFeeRefunded = true;
      Balances[seller] += sellerStakingFee;
    }

  

    function _setPredictionOutcome(uint256 _UID) internal {
      PredictionData storage _prediction = Predictions[_UID];
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

   function _setUpSellerClosing(uint256 _UID) internal {
     PredictionData storage _prediction = Predictions[_UID];
     require(_prediction.seller == msg.sender, "Not seller");
     require(block.timestamp > _prediction.endTime + 21600 &&
      block.timestamp < _prediction.endTime + 43200, "Event not cooled down");
      require(_prediction.state == State.Active, "Event no longer active");
      _prediction.state = State.Concluded;
      _setPredictionOutcome(_UID);
      _settleSeller(_UID);
   }

   /**pheripheral functions */
  function withdrawPrediction(uint256 _UID) external 
  onlySeller(_UID) notMined(_UID) {
   _refundSellerStakingFee(_UID);
    Predictions[_UID].state = State.Withdrawn;

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
    require(_vote > 1 && _vote <=3, "Vote cannot be neutral");
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

    if(Predictions[_UID].positiveOpeningVoteCount == 3){
        //prediction receives 60% positive validations
        Predictions[_UID].state = State.Active;
        UserProfile[Predictions[_UID].seller].totalPredictions += 1;
      }
      emit MinerOpeningVoteUpdated();
  }

  function updateMinerClosingVote(uint256 _UID, uint256 _tokenId, uint8 _vote) external isNftOwner(_tokenId){
    require(Predictions[_UID].validators[_tokenId].closing == ValidationStatus.Positive ||
    Predictions[_UID].validators[_tokenId].closing == ValidationStatus.Negative,
       "Closing vote not cast yet!"
       );
      /**Cool down period is 6hrs (21600 secs) after the game ends */
      require((block.timestamp > Predictions[_UID].endTime + 21600 && 
      block.timestamp < Predictions[_UID].endTime + 43200), "Event not cooled down");

      require(_vote > 1 && _vote <=3, "Vote cannot be neutral");
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
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                Balances[msg.sender] += _amount;
                   
            }
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
