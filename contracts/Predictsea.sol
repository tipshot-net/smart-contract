// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// @title A smart Contract managing bet prediction sales

contract PredictMarket {
    address payable public owner;
    mapping(uint32 =>  PredictionData) public Predictions;
    
    mapping(address => uint256) public Balances; 

    mapping(address => bytes32) public UsernameService;
    mapping(address => Profile) public SellerProfile;
    bool public locked = false;
    uint256 private lastLockedDate;

    enum Status {
        Pending,
        Accepted,
        Rejected,
        Won,
        Lost
    }

    struct PredictionData {
        uint32 UID;
        address seller;
        uint64 startTime;
        uint64 endTime;
        uint64 odd;
        uint64 price;
        mapping(address => bool) buyers;
        address[5] positiveValidators;
        address[5] negativeValidators;
        uint256 buyCount;
        Status status;
    }

    struct Profile {
        uint32 rating;
        uint256 wonCount;
        uint256 lostCount;
        uint256 totalPredictions;
        uint64 joinedDate;
        bytes32 bannerImage;
        bytes32 profileImage;
    }

    uint128 public miningFee;
    uint128 public sellerStakingFee;
    uint128 public minerStakingFee;
    uint128 public miningAllowance;
    uint32 public minerPercentage;
    uint32 public sellerPercentage;
    uint32 public minimumOdd;
    uint32 public minimumPrice;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    /**********************************/

    event PredictionCreated ();
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
      require(!locked, "Contract is in locked state");

      _;
    }

    modifier uniqueId(uint32 UID){
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
      uint32 _starttime, 
      uint32 _endtime, 
      uint32 _odd, 
      uint32 _price
      ){ 
        
        require(_sellerDoesMeetMinimumRequirements(
          _starttime, _endtime, _odd, _price),
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
        uint128 _miningFee,
        uint128 _sellerStakingFee,
        uint128 _minerStakingFee,
        uint128 _miningAllowance,
        uint32 _minerPercentage,
        uint32 _sellerPercentage,
        uint32 _minimumOdd,
        uint32 _minimumPrice
    ) {
        owner = payable(msg.sender);
        miningFee = _miningFee;
        sellerStakingFee = _sellerStakingFee;
        minerStakingFee = _minerStakingFee;
        miningAllowance = _miningAllowance;
        minerPercentage = _minerPercentage;
        sellerPercentage = _sellerPercentage;
        minimumOdd = _minimumOdd;
        minimumPrice = _minimumPrice;
    }

    function _sellerDoesMeetMinimumRequirements(
      uint32 _starttime, 
      uint32 _endtime, 
      uint32 _odd, 
      uint32 _price
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


    function _setupPrediction() internal  {



      
    }

    function createPredictionWithWallet() external {
      uint256 total = miningFee + sellerStakingFee;
      Balances[msg.sender] -= total;

      _setupPrediction();
      emit PredictionCreated();
    }

    function createPrediction() external payable {
      uint256 total = miningFee + sellerStakingFee;
      require(msg.value >= total, "Not enough ether");
      uint256 bal = msg.value - total;
      if(bal > 0){
        Balances[msg.sender] += bal;
      }

      _setupPrediction();
      emit PredictionCreated();
    }

    function lock() external onlyOwner {
      locked = true;
      lastLockedDate = block.timestamp;
    } 

    function unlock() external {
      require(locked && (msg.sender == owner || (block.timestamp >  lastLockedDate + 604800)),
      "Not owner!");
      locked = false;
    }

    


}
