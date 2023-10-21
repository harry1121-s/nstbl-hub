// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "../interfaces/IERC20Helper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract LoanManagerMock {

    using SafeERC20 for IERC20Helper;

    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public interest = 158_548_961;
    address public admin;
    uint256 public investedAssets;
    uint256 public startTime;

    constructor(address _admin) {
        admin = _admin;
    }

    function initializeTime() external {
        startTime = block.timestamp;
    }

    function deposit(address _asset, uint256 _amount) external {
        require(_asset == usdc, "LoanManager: invalid asset");
        require(_amount > 0, "LoanManager: invalid amount");
        investedAssets += _amount;
        IERC20Helper(_asset).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function updateInvestedAssets(uint256 _investedAssets) external {
        investedAssets = _investedAssets;
    }

    function getInvestedAssets(address _asset) external view returns (uint256) {
        return investedAssets;
    }

    function getMaturedAssets(address _asset) external view returns (uint256) {
        return investedAssets + ((investedAssets * (block.timestamp - startTime) * interest) / 1e17);
    }

    function getAssets(address _assest) external view returns (uint256) {
        return investedAssets + ((investedAssets * (block.timestamp - startTime) * interest) / 1e17);
    }
}
