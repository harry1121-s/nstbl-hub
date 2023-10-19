pragma solidity 0.8.21;

import "../interfaces/IERC20Helper.sol";
import "../interfaces/ILoanManager.sol";
import "./TokenLP.sol";

contract StakePoolStorage {
    event Stake(address indexed user, uint256 amount, uint256 rewards);
    event Unstake(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    address public immutable nstbl;
    address public immutable nstblVault;
    address public immutable lUSDC;
    address public immutable lUSDT;
    address public immutable usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public immutable loanManager;

    TokenLP public immutable lpToken;

    /*//////////////////////////////////////////////////////////////
                        STORAGE : Stake Pool
    //////////////////////////////////////////////////////////////*/
    address public admin;

    struct StakerInfo {
        bool ifATVLStaker;
        uint256 amount;
        uint256 rewardDebt;
        uint256 stakeTimeStamp;
    }

    struct PoolInfo {
        uint256 accNSTBLPerShare;
        uint64 allocPoint;
        uint64 stakeTimePeriod;
        uint64 earlyUnstakeFee;
    }

    uint256 public accNSTBLPerShare;
    uint256 public lastRewardTimeStamp;
    uint256 public totalStakedAmount;
    uint256 public yieldThreshold;

    address public atvl;
    uint256 public atvlStakeAmount;
    uint256 public atvlRewardDebt;
    uint256 public atvlExtraYield;

    mapping(uint256 => mapping(address => StakerInfo)) public stakerInfo;
    PoolInfo[] public poolInfo;
    uint256 public totalAllocPoint;

    mapping(address => bool) public authorizedCallers;
    mapping(int8 => uint256) public trancheTimePeriods;
    mapping(int8 => uint256) public trancheFee;
    mapping(int8 => uint256) public trancheBaseFee;

    uint256 public usdcInvestedAmount;
    uint256 public usdcMaturityAmount;
    uint256 public precision = 1e27;
}
