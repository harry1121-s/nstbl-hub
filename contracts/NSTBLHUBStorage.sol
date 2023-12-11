pragma solidity ^0.8.21;

import "./interfaces/IERC20Helper.sol";
import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/ILoanManager.sol";
import "@nstbl-stake-pool/contracts/interfaces/IStakePool.sol";
import "./interfaces/IATVL.sol";
import "./interfaces/INSTBLToken.sol";
import "./interfaces/INSTBLHub.sol";

contract NSTBLHUBStorage {

     /*//////////////////////////////////////////////////////////////
    IMMUTABLES & CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant REVISION = 1;

    address public immutable USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public immutable USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public immutable DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);


    /*//////////////////////////////////////////////////////////////
    State Variables
    //////////////////////////////////////////////////////////////*/

    uint256 public versionSlot;
    address public nealthyAddr;
    address public atvl;
    address public loanManager;
    address public aclManager;
    address public stakePool;
    address public nstblToken;
    address public chainLinkPriceFeed;
    uint256 public atvlBurnAmount;
    uint256 public burnedFromStakePool;

    uint256 public usdcInvested;

    mapping(address => uint256) public stablesBalances;

    address[3] public assets;

    address[3] public assetFeeds;
    uint256 public dt;
    uint256 public ub;
    uint256 public lb;
    uint256 public eqTh;
    uint256 public precision;

    uint256 public tBillPercent;

    //add new variables here to extended the storage
    //reduce the gap size equal the size of new variables: to maintain original layout and prevent collision
    uint256 [26] __gap;
}
