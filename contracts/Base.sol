// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

///@notice This contract contains all state variables, modifiers and internal functions used by multiple contracts.

abstract contract Base is Ownable {
  // ========== STATE VARIABLES ========== //

  ///@notice maps the generated UID to the prediction details
  mapping(uint256 => PredictionData) internal Predictions;

  mapping(address => uint256) public Balances;

  mapping(address => LockedFundsData) public LockedFunds;

  address public NFT_CONTRACT_ADDRESS;

  uint8 internal constant SIXTY_PERCENT = 3;

  uint8 internal constant EIGHTY_PERCENT = 4;

  uint8 internal constant MAX_VALIDATORS = 5;

  uint8 internal constant TO_PERCENTAGE = 100;

  uint16 internal constant BANK_ROLL = 1000;

  uint16 internal constant CONSTANT_VALUE_MULTIPLIER = 1000;

  uint16 internal constant SIX_HOURS = 21600;

  uint16 internal constant TWELVE_HOURS = 43200;

  uint32 internal constant TWENTY_FOUR_HOURS = 86400;

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

  struct LockedFundsData {
    uint256 amount;
    uint256 lastPushDate;
    uint256 releaseDate;
    uint256 totalInstances;
  }

  struct Vote {
    address miner;
    ValidationStatus opening;
    ValidationStatus closing;
    bool stakingFeeRefunded;
    bool correctValidation;
  }

  struct PredictionData {
    uint256 UID; // generated ID referencing to database prediction record
    address seller;
    uint256 startTime; //start time of first predicted event
    uint256 endTime; //end time of last predicted event
    uint16 odd;
    uint256 price;
    address[] buyersList;
    Vote[] votes;
    mapping(address => PurchaseData) buyers;
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
    ValidationStatus winningOpeningVote;
    ValidationStatus winningClosingVote;
  }

  struct PurchaseData {
    bool purchased;
    bool refunded;
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
    uint256 lifetimeAverageOdds;
  }

  uint256 public miningFee; // paid by seller -> to be shared by validators
  uint256 public sellerStakingFee; // paid by seller, staked per prediction
  uint256 public minerStakingFee; // paid by miner, staked per validation
  uint32 public minerPercentage; // %  for miner, In event of a prediction won
  uint16 public minWonCountForVerification; // minimum number of won predictions to be verified

  /**********************************/
  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  modifier uniqueId(uint256 UID) {
    require(Predictions[UID].UID == 0, "UID already exists");
    _;
  }

  modifier onlySeller(uint256 _UID) {
    require(msg.sender == Predictions[_UID].seller, "Only prediction seller");
    _;
  }

  modifier notSeller(uint256 _UID) {
    require(msg.sender != Predictions[_UID].seller, "Seller Unauthorized!");
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

  modifier newValidationRequest(uint256 _UID, uint256 _tokenId) {
    require(
      Predictions[_UID].validators[_tokenId].opening ==
        ValidationStatus.Neutral,
      "Invalid validation request"
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

  modifier notMined(uint256 _UID) {
    require(Predictions[_UID].validatorCount == 0, "Prediction already mined");
    _;
  }

  modifier isNftOwner(uint256 _tokenId) {
    require(TokenOwner[_tokenId] == msg.sender, "Not NFT Owner");
    _;
  }

  modifier predictionClosingOverdue(uint256 _UID) {
    require(
      block.timestamp > Predictions[_UID].endTime + (TWENTY_FOUR_HOURS * 3),
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

  ///@dev checks if prediction data meets requirements
  /// @param _startTime Timestamp of the kickoff time of the first prediction event
  /// @param _endTime Timestamp of the proposed end of the last prediction event
  ///@return bool

  function _sellerDoesMeetMinimumRequirements(
    uint256 _startTime,
    uint256 _endTime
  ) internal view returns (bool) {
    if (
      _startTime < block.timestamp ||
      _endTime < block.timestamp ||
      _endTime < _startTime ||
      _startTime > block.timestamp + TWENTY_FOUR_HOURS ||
      (_endTime - _startTime) > (TWENTY_FOUR_HOURS * 2)
    ) {
      return false;
    }

    return true;
  }
}
