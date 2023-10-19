// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPool {
    function deposit(uint256 _assets, address _receiver) external;
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_);
    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);
    function balanceOf(address account) external view returns (uint256);
    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);
    function convertToShares(uint256 assets_) external view returns (uint256 shares_);
    function convertToExitShares(uint256 amount_) external view returns (uint256 shares_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
    function totalAssets() external view returns (uint256 totalAssets_);
    function decimals() external returns (uint8);
    function totalSupply() external view returns (uint256);
    function maxDeposit(address receiver_) external returns (uint256 maxAssets_);
}
