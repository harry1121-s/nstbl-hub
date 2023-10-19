// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

contract LoanManagerMock {
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public interest = 158548961;
    address public admin;
    uint256 public investedAssets;
    uint256 public startTime;

    constructor(address _admin) {
       admin = _admin;
    }

    function initializeTime() external {
        startTime = block.timestamp;
    }

    function updateInvestedAssets(uint256 _investedAssets) external {
        investedAssets = _investedAssets;
    }

    function getInvestedAssets(address _asset) external view returns(uint256) {
        return investedAssets;
    }

    function getMaturedAssets(address _asset) external view returns (uint256) {
        return investedAssets + ((investedAssets*(block.timestamp - startTime) * interest) / 1e17);
    }

}
