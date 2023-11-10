// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ILoanManager {
    function deposit(uint256 _amount) external;
    function requestRedeem(uint256 _amount) external;
    function redeem() external;
    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    function getAssets(address _asset, uint256 _lpTokenAmount) external view returns (uint256);
    function getInvestedAssets(address _assets) external view returns (uint256);
    function getMaturedAssets() external view returns (uint256);
    function awaitingRedemption(address _asset) external view returns (bool);
    function getLPTotalSupply() external view returns (uint256);
}
