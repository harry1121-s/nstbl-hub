// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { IERC20Helper } from "@nstbl-loan-manager/contracts/interfaces/IERC20Helper.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Test, console } from "forge-std/Test.sol";

contract Utils is Test{
    using SafeERC20 for IERC20Helper;
    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint256 public dt = 98 * 1e6;
    uint256 public ub = 97 * 1e6;
    uint256 public lb = 96 * 1e6;
    address public owner = vm.addr(123);
    address public nealthyAddr = vm.addr(456);
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public user3 = vm.addr(3);
    address public user4 = vm.addr(4);
    address public compliance = vm.addr(4);

    address public poolDelegateUSDC = 0x8c8C2431658608F5649B8432764a930c952d8A98;
    address public NSTBL_HUB = 0x749f88e87EaEb030E478164cFd3681E27d0bcB42;
    address public MAPLE_USDC_CASH_POOL = 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92;
    address public MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;
    address public WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;

     /*//////////////////////////////////////////////////////////////
                               HELPERS
    //////////////////////////////////////////////////////////////*/

    function erc20_approve(address asset_, address account_, address spender_, uint256 amount_) internal {
        vm.startPrank(account_);
        IERC20Helper(asset_).approve(spender_, amount_);
        vm.stopPrank();
    }

    function erc20_transfer(address asset_, address account_, address destination_, uint256 amount_) internal {
        vm.startPrank(account_);
        IERC20Helper(asset_).transfer(destination_, amount_);
        vm.stopPrank();
    }

    function erc20_deal(address asset_, address account_, uint256 amount_) internal {
        if (asset_ == USDT) deal(USDT, account_, amount_, true);
        else if (asset_ == USDC) deal(USDC, account_, amount_, true);
    }

}
