pragma solidity ^0.8.21;

import "./interfaces/IERC20Helper.sol";
import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/ILoanManager.sol";

contract NSTBLHUBStorage {

    address public admin;
    address public nealthyAddr;
    address public loanManager;
    address public stakePool;
    address public nstblToken;
    address public chainLinkPriceFeed;
    address public immutable usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public immutable dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
                                            //usdc, usdt, dai
    address[3] public assetFeeds = [0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6, 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D, 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9];
    uint256 public minDeposit;
    uint256 public dt;
    uint256 public ub;
    uint256 public lb;

}