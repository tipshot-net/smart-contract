// contracts/Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address payable public owner; //The contract deployer and owner

  /** contract can be locked in case of emergencies */
  bool public locked = false;

  uint256 private lastLockedDate;

  /** nominated address can claim ownership of contract 
    and automatically become owner */
  address payable private nominatedOwner;

  event IsLocked(bool lock_status);
  event NewOwnerNominated(address nominee);
  event OwnershipTransferred(address newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner, "Unauthorized access to contract");
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
    lastLockedDate = block.timestamp;
    emit IsLocked(locked);
  }

  function unlock() external {
    require(
      locked &&
        (msg.sender == owner || (block.timestamp > lastLockedDate + 604800)),
      "Not owner!"
    );
    locked = false;
    emit IsLocked(locked);
  }

  function nominateNewOwner(address _address)
    external
    onlyOwner
    notZeroAddress(_address)
  {
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
