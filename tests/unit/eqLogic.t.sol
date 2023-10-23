pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20, IERC20Helper, BaseTest } from "../helpers/BaseTest.t.sol";

contract EqLogicTest is BaseTest {
    using SafeERC20 for IERC20Helper;
    using SafeERC20 for IERC20;
    function setUp() public override {
        super.setUp();
    }

    function test_deposit() external {

        //deal USDC, USDT, DAI to the hub
        // deal(USDC, address(nstblHub), 8e5 * 1e18);
        // deal(USDT, address(nstblHub), 1e5 * 1e18);
        // deal(DAI, address(nstblHub), 1e5 * 1e18);
        console.log("USDC bal: ", IERC20Helper(USDC).balanceOf(address(eqlogic)));
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);


        // loanManager.updateInvestedAssets(7e5 * 1e18);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = eqlogic.previewDeposit(1e6 * 1e18);
        console.log("usdcAmt: ", usdcAmt);
        console.log("usdtAmt: ", usdtAmt);
        console.log("daiAmt: ", daiAmt);


        deal(USDC, user1, usdcAmt);
        deal(USDT, user1, usdtAmt);
        deal(DAI, user1, daiAmt);

        
        vm.startPrank(user1);
        IERC20Helper(USDC).safeIncreaseAllowance(address(eqlogic), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(eqlogic), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(eqlogic), daiAmt);
        eqlogic.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopPrank();

        assertEq(usdcAmt-tBillAmt, IERC20Helper(USDC).balanceOf(address(eqlogic)));
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(address(loanManager)));
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(eqlogic)));
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(eqlogic)));

        assertEq(usdcAmt+usdtAmt+daiAmt, nstblToken.balanceOf(user1));

    }
}
