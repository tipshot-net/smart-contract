// contracts/Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address payable public owner; //The contract deployer and owner

  /** contract can be locked in case of emergencies */
  bool public locked = false;

  /** nominated address can claim ownership of contract 
    and automatically become owner */
  address payable public nominatedOwner;

  event IsLocked(bool lock_status);
  event NewOwnerNominated(address nominee);
  event OwnershipTransferred(address newOwner);

  /// @notice Only allows the `owner` to execute the function.
  modifier onlyOwner() {
    require(msg.sender == owner, "Unauthorized access");
    _;
  }

  modifier isOpen() {
    require(!locked, "Contract in locked state");

    _;
  }

  modifier notZeroAddress(address _address) {
    require(_address != address(0), "Cannot specify 0 address");
    _;
  }

  function lock() external onlyOwner {
    locked = true;
    emit IsLocked(locked);
  }

  function unlock() external onlyOwner {
    locked = false;
    emit IsLocked(locked);
  }

  /**
    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param _address Address of the new owner.
   */

  function nominateNewOwner(address _address)
    external
    onlyOwner
    notZeroAddress(_address)
  {
    require(_address != owner, "Owner address can't be nominated");
    nominatedOwner = payable(_address);
    emit NewOwnerNominated(nominatedOwner);
  }

  /**  @notice Needs to be called by `pendingOwner` to claim ownership.
   * @dev Transfers ownership of the contract to a new account (`nominatedOwner`).
   * Can only be called by the current owner.
   */

  function transferOwnership() external {
    require(nominatedOwner != address(0), "Nominated owner not set");
    require(msg.sender == nominatedOwner, "Not a nominated owner");
    owner = nominatedOwner;
    emit OwnershipTransferred(owner);
  }
}
