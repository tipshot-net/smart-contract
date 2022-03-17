// contracts/PredictNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PredictNFT is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  uint256 public sellingPrice;
  uint256 public totalMinted;
  uint256 public mintLimit;
  uint256 internal withdrawableAmount;
  mapping(address => bool) public canMint;
  mapping(address => uint256) public balances;

  event NewSellingPrice(uint256 price);
  event MintLimitIncreased(uint256 newLimit);
  event AddressWhitelisted(address whitelistedAddress);
  event UserWithdrawal(address user, uint256 amount, uint256 balance);
  event ManagerWithdrawal(address recipient, uint256 amount, uint256 balance);

  constructor() ERC721("PredictSea", "PST") {
    owner = payable(msg.sender);
  }

  function mintToken(address miner, string memory tokenURI)
    public
    returns (uint256)
  {
    require(canMint[miner], "Cannot mint token");
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();
    _mint(miner, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    canMint[miner] = false;
    return newTokenId;
  }

  function setSellingPrice(uint256 _price) external onlyOwner {
    sellingPrice = _price;
    emit NewSellingPrice(_price);
  }

  function increaseMintLimit(uint256 _limit) external onlyOwner {
    mintLimit += _limit;
    emit MintLimitIncreased(_limit);
  }

  function whitelist() external payable {
    require(totalMinted < mintLimit, "Current limit reached");
    require(msg.value >= sellingPrice, "Not enough ether sent");
    require(!canMint[msg.sender], "Unused mint access");
    canMint[msg.sender] = true;
    totalMinted += 1;
    withdrawableAmount += sellingPrice;
    uint256 _balance = msg.value - sellingPrice;
    if (_balance > 0) {
      (bool success, ) = payable(msg.sender).call{value: _balance}("");
      if (!success) {
        balances[msg.sender] += _balance;
      }
    }
    emit AddressWhitelisted(msg.sender);
  }

  function withdrawFromBalances(uint256 _amount) external {
    require(balances[msg.sender] >= _amount, "Not enough balance");
    balances[msg.sender] -= _amount;
    (bool sent, ) = msg.sender.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit UserWithdrawal(msg.sender, _amount, balances[msg.sender]);
  }

  function managerWithdrawal(address _to, uint256 _amount) external onlyOwner {
    require(withdrawableAmount >= _amount, "Not enough to withdraw");
    withdrawableAmount -= _amount;
    (bool sent, ) = _to.call{value: _amount}("");
    require(sent, "Failed to send Ether");
    emit ManagerWithdrawal(_to, _amount, withdrawableAmount);
  }

  receive() external payable {
    balances[msg.sender] += msg.value;
  }
}
