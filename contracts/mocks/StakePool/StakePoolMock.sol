// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./StakePoolStorage.sol";

contract StakePoolMock is StakePoolStorage{
    using SafeERC20 for IERC20Helper;

    uint256 private _locked = 1;

    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "SP::NOT ADMIN");
        _;
    }

    modifier onlyATVL() {
        require(msg.sender == atvl, "SP::NOT ATVL");
        _;
    }

    modifier authorizedCaller() {
        require(authorizedCallers[msg.sender], "SP::NOT AUTHORIZED");
        _;
    }

    constructor(
        address _admin,
        address _nstbl
    ) {
        admin = _admin;
        nstbl = _nstbl;
    }

    function init(address _nstblvault) external onlyAdmin {
        nstblVault = _nstblvault;
    }

    function setAuthorizedCaller(address _caller, bool _isAuthorized) external onlyAdmin {
        authorizedCallers[_caller] = _isAuthorized;
    }
   
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

     function poolLength() public view returns (uint256 _pools) {
        _pools = poolInfo.length;
    }

    function configurePool(uint256 _allocPoint, uint256 _stakeTimePeriod, uint256 _earlyUnstakeFee) external onlyAdmin {
        totalAllocPoint += _allocPoint;
        poolInfo.push(PoolInfo({
            accNSTBLPerShare: 0,
            allocPoint: uint64(_allocPoint),
            stakeTimePeriod: uint64(_stakeTimePeriod),
            earlyUnstakeFee: uint64(_earlyUnstakeFee)
        }));
    }

    function getUserStakedAmount(address _user, uint256 _poolId)external view returns(uint256 _stakedAmount) {
        StakerInfo memory staker = stakerInfo[_poolId][_user];   
        _stakedAmount = staker.amount;
    }

    //TODO: get user staked amount + rewards function

    function stake(uint256 _amount, address _userAddress, uint256 _poolId) public authorizedCaller {
        require(_amount > 0, "SP::INVALID AMOUNT");
        require(_poolId < poolInfo.length, "SP::INVALID POOL");
        uint256 pendingNSTBL;

        StakerInfo storage staker = stakerInfo[_poolId][_userAddress];

        IERC20Helper(nstbl).safeTransferFrom(msg.sender, address(this), _amount);

       
        staker.amount += _amount;
        staker.stakeTimeStamp = block.timestamp;
        totalStakedAmount += _amount;

        emit Stake(_userAddress, _amount, pendingNSTBL);
    }

    function unstake(uint256 _amount, address _userAddress, uint256 _poolId) public authorizedCaller {
        require(_amount > 0, "SP::INVALID AMOUNT");
        require(_poolId < poolInfo.length, "SP::INVALID POOL");

        StakerInfo storage staker = stakerInfo[_poolId][_userAddress];

        require(_amount <= staker.amount, "SP::INVALID AMOUNT");

       
        staker.amount -= _amount;
        totalStakedAmount -= _amount;
        IERC20Helper(nstbl).safeTransfer(msg.sender, _amount);

        emit Unstake(_userAddress, _amount);
    }
}
