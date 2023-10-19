// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IStakePool {
    function stake(uint256 _amount, address _userAddress, uint256 _poolId) external;
    function unstake(uint256 _amount, address _userAddress, uint256 _poolId) external;
    function getUserStakedAmount(address _user, uint256 _poolId) external view returns (uint256 _stakedAmount);
}
