pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Helper, BaseTest } from "../helpers/BaseTest.t.sol";

contract NSTBLHubTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_NSTBLBalance() external {
        uint256 balance = nstblToken.balanceOf(admin);
        console.log(balance);
    }

    function test_transferNSTBL() external {
        uint256 balBefore = nstblToken.balanceOf(admin);
        erc20_transfer(address(nstblToken), admin, user1, 1e6 * 1e18);
        uint256 balAfter = nstblToken.balanceOf(admin);
        uint256 balUser1 = nstblToken.balanceOf(user1);
        assertEq(balBefore - balAfter, 1e6 * 1e18);
    }

    function test_stake() external {
        _stakeNstbl(user1, 1e6 * 1e18, 0);
        assertEq(1e6 * 1e18, nstblToken.balanceOf(address(stakePool)));
        assertEq(1e6 * 1e18, stakePool.getUserStakedAmount(user1, 0));
        assertEq(0, nstblToken.balanceOf(nealthyAddr));
        assertEq(99e6 * 1e18, nstblToken.balanceOf(admin));
    }

    function test_unstake_noDepeg() external {
        _stakeNstbl(user1, 1e6 * 1e18, 0);

        //maintaining exact proportions
        deal(USDC, address(nstblHub), 8e5 * 1e18);
        deal(USDT, address(nstblHub), 1e5 * 1e18);
        deal(DAI, address(nstblHub), 1e5 * 1e18);

        usdcPriceFeedMock.updateAnswer(981e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        vm.expectRevert("HUB::UNAUTH");
        nstblHub.unstake(1e6 * 1e18, 0, user1);

        vm.startPrank(nealthyAddr);
        nstblHub.unstake(1e6 * 1e18, 0, user1);
        vm.stopPrank();
    }

    function test_unstake_OneDepeg_InsuffLiquidity() external {
        erc20_transfer(address(nstblToken), admin, address(atvl), 12_000 * 1e18);
        _stakeNstbl(user1, 1e6 * 1e18, 0);

        //maintaining exact proportions
        deal(USDC, address(nstblHub), 8e5 * 1e18);
        deal(USDT, address(nstblHub), 1e5 * 1e18);
        deal(DAI, address(nstblHub), 1e5 * 1e18);

        usdcPriceFeedMock.updateAnswer(981e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(975e5);

        vm.expectRevert("HUB::UNAUTH");
        nstblHub.unstake(1e6 * 1e18, 0, user1);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyBefore = nstblToken.totalSupply();
        uint256 stakeAmountBefore = stakePool.getUserStakedAmount(user1, 0);

        vm.startPrank(nealthyAddr);
        nstblHub.unstake(1e6 * 1e18, 0, user1);
        vm.stopPrank();

        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyAfter = nstblToken.totalSupply();
        uint256 stakeAmountAfter = stakePool.getUserStakedAmount(user1, 0);

        assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
        assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
    }

    function test_unstake_TwoDepeg_InsuffLiquidity() external {
        erc20_transfer(address(nstblToken), admin, address(atvl), 12_000 * 1e18);
        _stakeNstbl(user1, 1e6 * 1e18, 0);

        //maintaining exact proportions
        deal(USDC, address(nstblHub), 8e5 * 1e18);
        deal(USDT, address(nstblHub), 1e5 * 1e18);
        deal(DAI, address(nstblHub), 1e5 * 1e18);

        usdcPriceFeedMock.updateAnswer(981e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(965e5);

        vm.expectRevert("HUB::UNAUTH");
        nstblHub.unstake(1e6 * 1e18, 0, user1);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyBefore = nstblToken.totalSupply();
        uint256 stakeAmountBefore = stakePool.getUserStakedAmount(user1, 0);

        vm.startPrank(nealthyAddr);
        nstblHub.unstake(1e6 * 1e18, 0, user1);
        vm.stopPrank();

        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyAfter = nstblToken.totalSupply();
        uint256 stakeAmountAfter = stakePool.getUserStakedAmount(user1, 0);

        assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
        assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
    }

    function test_unstake_ThreeDepeg_InsuffLiquidity() external {
        erc20_transfer(address(nstblToken), admin, address(atvl), 100_000 * 1e18);
        _stakeNstbl(user1, 1e6 * 1e18, 0);

        //maintaining exact proportions
        deal(USDC, address(nstblHub), 8e5 * 1e18);
        deal(USDT, address(nstblHub), 1e5 * 1e18);
        deal(DAI, address(nstblHub), 1e5 * 1e18);

        usdcPriceFeedMock.updateAnswer(959e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(965e5);

        vm.expectRevert("HUB::UNAUTH");
        nstblHub.unstake(1e6 * 1e18, 0, user1);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyBefore = nstblToken.totalSupply();
        uint256 stakeAmountBefore = stakePool.getUserStakedAmount(user1, 0);

        vm.startPrank(nealthyAddr);
        nstblHub.unstake(1e6 * 1e18, 0, user1);
        vm.stopPrank();

        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyAfter = nstblToken.totalSupply();
        uint256 stakeAmountAfter = stakePool.getUserStakedAmount(user1, 0);

        assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
        assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
    }

    function test_unstake_ThreeDepeg_SuffLiquidity() external {
        erc20_transfer(address(nstblToken), admin, address(atvl), 100_000 * 1e18);
        _stakeNstbl(user1, 1e6 * 1e18, 0);

        //maintaining exact proportions
        deal(USDC, address(nstblHub), 800e5 * 1e18);
        deal(USDT, address(nstblHub), 1e5 * 1e18);
        deal(DAI, address(nstblHub), 1e5 * 1e18);

        usdcPriceFeedMock.updateAnswer(959e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(965e5);

        vm.expectRevert("HUB::UNAUTH");
        nstblHub.unstake(1e6 * 1e18, 0, user1);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyBefore = nstblToken.totalSupply();
        uint256 stakeAmountBefore = stakePool.getUserStakedAmount(user1, 0);

        vm.startPrank(nealthyAddr);
        nstblHub.unstake(1e6 * 1e18, 0, user1);
        vm.stopPrank();

        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
        uint256 nstblSupplyAfter = nstblToken.totalSupply();
        uint256 stakeAmountAfter = stakePool.getUserStakedAmount(user1, 0);

        assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
        assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
    }
}
