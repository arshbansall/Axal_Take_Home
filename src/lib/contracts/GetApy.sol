// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/protocol/configuration/PoolAddressesProvider.sol";
import "https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/helpers/UiPoolDataProviderV3.sol";
import "https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol";
import "https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/helpers/AaveProtocolDataProvider.sol";

contract YearlyYieldEstimator {

  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  address public constant AAVE_PROTOCOL_PROVIDER_SEPOLIA = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31;
  uint256 constant RAY = 1e27;
  AaveProtocolDataProvider protocolDataProvider;
  TokenData[] public tokenDatas;
  address public owner;
  uint256 transferAmount;

  event FundsDeposited(address indexed from, uint256 amount);

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor() {
    owner = msg.sender;
    transferAmount = 0.001 ether;
    protocolDataProvider = AaveProtocolDataProvider(AAVE_PROTOCOL_PROVIDER_SEPOLIA);
    IPoolDataProvider.TokenData[] memory rawTokenDatas = protocolDataProvider.getAllReservesTokens();

    for(uint i = 0; i < 5; i++) {
      TokenData memory newTokenData = TokenData({
        symbol: rawTokenDatas[i].symbol,
        tokenAddress: rawTokenDatas[i].tokenAddress
      });

      tokenDatas.push(newTokenData);
    }
  }

  function deposit() external payable onlyOwner {
    require(msg.value >= transferAmount, "Must deposit at least the transfer amount");
    emit FundsDeposited(msg.sender, msg.value);
  }

  function getEstimatedAPY(string memory symbol) external returns (bool, uint256, bool) {

    uint256 highestYield = 0;
    uint256 clientSymbolYield = 0;
    string memory highestYieldSymbol = "";

    for(uint i = 0; i < tokenDatas.length; i++) {
      (, , , , , uint256 liquidityRate, , , , , ,) = protocolDataProvider.getReserveData(tokenDatas[i].tokenAddress);
      uint256 yield = (liquidityRate * 10000) / RAY;

      if(keccak256(abi.encodePacked(tokenDatas[i].symbol)) == keccak256(abi.encodePacked(symbol))) {
        clientSymbolYield = yield;
      }
        
      if(yield > highestYield) {
        highestYield = yield;
        highestYieldSymbol = tokenDatas[i].symbol;
      }
    }


    if(keccak256(abi.encodePacked(highestYieldSymbol)) == keccak256(abi.encodePacked(symbol))) {
      // transfer funds
      bool transferSuccess = sendBounty(msg.sender);
      return (true, highestYield, transferSuccess);

    } else {
      return (false, clientSymbolYield, false);
    }
  }

  function sendBounty(address recipient) internal returns (bool) {
    require(address(this).balance >= transferAmount, "Owner has insufficient funds");
    (bool sent, ) = payable(recipient).call{value: transferAmount}("");
    return sent;
  }

  receive() external payable {
    emit FundsDeposited(msg.sender, msg.value);
  }
}
