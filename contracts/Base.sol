// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



///@notice This contract contains all state variables, modifiers and internal functions used by multiple contracts.

abstract contract Base is Ownable {

  // ========== STATE VARIABLES ========== //

  ///@notice maps the generated UID to the prediction details
  mapping(uint256 => PredictionData) public Predictions;

  //      tokenId          prediction id
  mapping(uint256 => mapping(uint256 => Vote)) public Validations; //maps miners tokenId to vote data

  mapping(address => uint256) public Balances;

  mapping(address => LockedFundsData) public LockedFunds;

  address public NFT_CONTRACT_ADDRESS;

  uint8 internal constant SIXTY_PERCENT = 3;

  uint8 internal constant EIGHTY_PERCENT = 4;

  uint8 internal constant MAX_VALIDATORS = 5;

  uint8 internal constant TO_PERCENTAGE = 100;

  uint16 internal constant BANK_ROLL = 1000;

  uint16 internal constant CONSTANT_VALUE_MULTIPLIER = 1000;

  uint16 internal constant HOURS = 3600;

  

  mapping(address => uint256[]) public BoughtPredictions;

  mapping(address => uint256[]) public OwnedPredictions;

  mapping(address => ValidationData[]) public OwnedValidations;

  mapping(uint256 => address) internal TokenOwner;

  mapping(uint256 => mapping(address => bool)) internal ActiveBoughtPredictions;

  mapping(uint256 => mapping(address => bool)) internal ActiveValidations;

  mapping(uint256 => mapping(address => bool)) internal ActiveSoldPredictions;

  mapping(address => PerformanceData) public Performance;

  /// @notice maps username to address -> verified sellers only
  mapping(bytes32 => address) public UsernameService;

  mapping(address => Profile) public UserProfile;

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
    bool assigned;
    ValidationStatus opening;
    ValidationStatus closing;
    bool stakingFeeRefunded;
    bool correctValidation;
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
    //address[] buyersList;
    Vote[] votes;
   // mapping(address => PurchaseData) buyers;
    uint8 validatorCount;
    // uint8 positiveOpeningVoteCount;
    // uint8 negativeOpeningVoteCount;
    // uint8 positiveClosingVoteCount;
    // uint8 negativeClosingVoteCount;
    //uint64 buyCount; // total count of purchases
    Status status;
    State state;
    //uint256 totalEarned;
    bool sellerStakingFeeRefunded;
    bool withdrawnEarnings;
    // ValidationStatus winningOpeningVote;
    // ValidationStatus winningClosingVote;
  }

  struct PurchaseData {
    bool purchased;
    bool refunded;
  }

  struct ValidationData {
    uint256 id;
    uint256 tokenId;
    string key;
    }

  struct PredictionHistory {
    uint32 odd;
    uint256 winnings;
  }

  struct Profile {
    bytes32 username;
    uint256 wonCount;
    uint256 lostCount;
    uint256 totalPredictions;
    uint256 totalOdds;
    uint256 grossWinnings;
    PredictionHistory[] last30Predictions;
  }

  struct PerformanceData {
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
  }

  uint256 public miningFee; // paid by seller -> to be shared by validators
  uint256 public sellerStakingFee; // paid by seller, staked per prediction
  uint256 public minerStakingFee; // paid by miner, staked per validation
  uint32 public minerPercentage; // %  for miner, In event of a prediction won

  ///@notice Seller requires needs to surpass 100 Won predictions to be eligible to create a verified username
  uint16 public minWonCountForVerification = 100; 



  uint256[] public miningPool;

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

  modifier predictionEventNotStarted(uint256 _UID) {
    require(
      Predictions[_UID].startTime > block.timestamp,
      "Event already started"
    );
    _;
  }

  modifier predictionEventAlreadyStarted(uint256 _UID) {
    require(block.timestamp > Predictions[_UID].startTime, "Event not started");
    _;
  }

  modifier validatorCountIncomplete(uint256 _UID) {
    require(
      Predictions[_UID].validatorCount < MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }

  modifier validatorCountComplete(uint256 _UID) {
    require(
      Predictions[_UID].validatorCount == MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }


  modifier predictionActive(uint256 _UID) {
    require(
      Predictions[_UID].state == State.Active,
      "Prediction currently inactive"
    );
    _;
  }

  modifier notMined(uint256 _id) {
    require(Predictions[_id].validatorCount == 0, "Prediction already mined");
    _;
  }

  modifier isNftOwner(uint256 _tokenId) {
    require(TokenOwner[_tokenId] == msg.sender, "Not NFT Owner");
    _;
  }

  modifier predictionClosingOverdue(uint256 _UID) {
    require(
      block.timestamp > Predictions[_UID].endTime + (24 * HOURS),
      "Prediction closing not overdue"
    );
    _;
  }

  /**********************************/
  /*╔═════════════════════════════╗
    ║             END             ║
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/
  /**********************************/

  

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
        add(block.timestamp, mul(8 , HOURS)) > _startTime ||
        _startTime > add(block.timestamp, mul(24 , HOURS)) ||
        sub(_endTime, _startTime) > mul(24 , HOURS)
      ) {
        return false;
      }

      return true;
    }

  function getMiningPoolLength() public view returns(uint256 length) {
    return miningPool.length;
  }

  function getOwnedPredictionsLength(address seller) public view returns(uint256 length) {
    return OwnedPredictions[seller].length;
  }

  function getOwnedValidationsLength(address miner) public view returns(uint256 length) {
    return OwnedValidations[miner].length;
  }

  

}
