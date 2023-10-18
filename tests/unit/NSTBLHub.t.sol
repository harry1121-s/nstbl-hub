pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { BaseTest } from "../helpers/Setup.t.sol";

contract NSTBLHubTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testNSTBLBalance() external {
        uint256 balance = nstblToken.balanceOf(admin);
        console.log(balance);
    }

    function testTransferNSTBL() external {
        uint256 balBefore = nstblToken.balanceOf(admin);
        erc20_transfer(address(nstblToken), admin, user1, 1e6 * 1e18);
        uint256 balAfter = nstblToken.balanceOf(admin);
        uint256 balUser1 = nstblToken.balanceOf(user1);
        assertEq(balBefore - balAfter, 1e6 * 1e18);
    }

    function testStake() external {
        erc20_transfer(address(nstblToken), admin, nealthyAddr, 1e6 * 1e18);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), 1e6 * 1e18);
        nstblHub.stake(1e6 * 1e18, 0, user1);
        vm.stopPrank();
        assertEq(1e6 * 1e18, nstblToken.balanceOf(address(stakePool)));
        assertEq(1e6 * 1e18, stakePool.getUserStakedAmount(user1, 0));
        assertEq(0, nstblToken.balanceOf(nealthyAddr));
        assertEq(99e6 * 1e18, nstblToken.balanceOf(admin));

    }
}