// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ILoanManager {
    function deposit(address _asset, uint256 _amount) external;
    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    function getAssets(address _asset) external view returns (uint256);
    function getInvestedAssets(address _assets) external view returns (uint256);
    function getMaturedAssets(address _assets) external view returns (uint256);
}
