pragma solidity ^0.8.21;

import "./interfaces/IERC20Helper.sol";
import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/IStakePool.sol";
import "./interfaces/IATVL.sol";

contract NSTBLHUBStorage {
    uint256 versionSlot;
    address public nealthyAddr;
    address public atvl;
    address public loanManager;
    address public aclManager;
    address public stakePool;
    address public nstblToken;
    address public chainLinkPriceFeed;
    uint256 public atvlBurnAmount;
    uint256 public stakePoolBurnAmount;

    uint256 public usdcDeposited;
    uint256 public usdtDeposited;
    uint256 public daiDeposited;
    uint256 public usdcInvested;

    uint256 usdcRequestedForRedeem;
    uint256 public usdcRedeemed;

    mapping(address => uint256) public assetAllocation;

    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    //usdc, usdt, dai
    address[3] public assets = [
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    ];
    //usdc, usdt, dai
    // address[3] public assetFeeds = [
    //     0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6,
    //     0x3E7d1eAB13ad0104d2750B8863b489D65364e32D,
    //     0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
    // ];

    address[3] public assetFeeds;
    uint256 public dt;
    uint256 public ub;
    uint256 public lb;
    uint256 public eqTh;
    uint256 public precision = 1e24;

    uint256 public liquidPercent;
    uint256 public tBillPercent;
    uint256 public marginPercent;
}
