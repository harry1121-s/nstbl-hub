// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { IERC20, IERC20Helper } from "../../../contracts/interfaces/IERC20Helper.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Utils is Test {
    using SafeERC20 for IERC20Helper;

    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public MAPLE_USDC_CASH_POOL = 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92;
    address public MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;

    address public admin = address(123);
    address public nealthyAddr = address(456);
    address public user1 = address(0xb3DD7E7F21Be44FC53c8d9857a71474A40BE64f7);
    address public user2 = address(0x63bFB5b6F8785A61d547D62614F6A873B1111A6B);
    address public user3 = address(3);

    uint256 public dt = 98 * 1e6;
    uint256 public ub = 97 * 1e6;
    uint256 public lb = 96 * 1e6;
    /*//////////////////////////////////////////////////////////////
                               HELPERS
    //////////////////////////////////////////////////////////////*/

    // function erc20_approve(address asset_, address account_, address spender_, uint256 amount_) internal {
    //     vm.startPrank(account_);
    //     IERC20(asset_).approve(spender_, amount_);
    //     vm.stopPrank();
    // }

    function erc20_transfer(address asset_, address account_, address destination_, uint256 amount_) internal {
        vm.startPrank(account_);
        IERC20Helper(asset_).safeTransfer(destination_, amount_);
        vm.stopPrank();
    }
}
