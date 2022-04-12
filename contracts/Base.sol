// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

///@notice This contract contains all state variables, modifiers and internal functions used by multiple contracts.

abstract contract Base is Ownable {
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

  mapping(uint256 => mapping(address => bool)) internal ActiveBoughtPredictions;

  mapping(uint256 => mapping(address => bool)) internal ActiveValidations;

  mapping(uint256 => mapping(address => bool)) internal ActiveSoldPredictions;

  mapping(address => Profile) public User;

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
}
