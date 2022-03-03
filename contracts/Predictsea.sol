// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "hardhat/console.sol";

// @title PredictSea {Blockchain powered sport prediction marketplace}

contract Main {
    address payable public owner;   //The contract deployer and owner

   /**
   maps unique id of prediction in the centralized server
   to each contract struct record.
    */
    mapping(uint256 =>  PredictionData) public Predictions; 

    mapping(address => uint256) public Balances; 

  /** users can have thier accounts verified by 
  purchasing a unique username mapped to thier address */
    mapping(address => bytes32) public UsernameService;

    mapping(address => Profile) public SellerProfile;

    /** contract can be locked in case of emergencies */
    bool public locked = false;


    uint256 private lastLockedDate;

    /** nominated address can claim ownership of contract 
    and automatically become owner */
    address payable private nominatedOwner;

    enum Status {
        Pending,
        Accepted,
        Rejected,
        Won,
        Lost
    }

    struct PredictionData {
        uint256 UID; // reference to database prediction record
        address seller;
        uint256 startTime; //start time of first predicted event
        uint256 endTime; //start time of last predicted event
        uint16 odd;
        uint256 price;
        mapping(address => bool) buyers;
        address[5] positiveValidators; //miners that upvoted 
        address[5] negativeValidators; //miners that downvoted
        uint64 buyCount; // total count of purchases
        Status status;
    }

    struct Profile {
        uint8 rating;
        uint256 wonCount;
        uint256 lostCount;
        uint256 totalPredictions;
        uint256 joinedDate;
        bytes32 bannerImage;
        bytes32 profileImage;
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

    modifier onlySeller(uint32 _predictionId){
      require(msg.sender == Predictions[_predictionId].seller, "Only prediction seller");
      _;
    }

    modifier notSeller(uint32 _predictionId){
      require(msg.sender != Predictions[_predictionId].seller, "Seller Unauthorized!");
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
      ) external {
      uint256 total = miningFee + sellerStakingFee;
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
