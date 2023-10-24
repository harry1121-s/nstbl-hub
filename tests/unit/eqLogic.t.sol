pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20, IERC20Helper, BaseTest, eqLogic } from "../helpers/BaseTest.t.sol";

contract EqLogicTest is BaseTest {
    using SafeERC20 for IERC20Helper;
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
    }

    // function test_deposit() external {

    //     console.log("USDC bal: ", IERC20Helper(USDC).balanceOf(address(eqlogic)));
    //     //nodepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(985e5);

    //     // loanManager.updateInvestedAssets(7e5 * 1e18);

    //     uint256 usdcAmt;
    //     uint256 usdtAmt;
    //     uint256 daiAmt;
    //     uint256 tBillAmt;

    //     (usdcAmt, usdtAmt, daiAmt, tBillAmt) = eqlogic.previewDeposit(1e6 * 1e18);
    //     console.log("usdcAmt: ", usdcAmt);
    //     console.log("usdtAmt: ", usdtAmt);
    //     console.log("daiAmt: ", daiAmt);

    //     deal(USDC, user1, usdcAmt);
    //     deal(USDT, user1, usdtAmt);
    //     deal(DAI, user1, daiAmt);

    //     vm.startPrank(user1);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(eqlogic), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(eqlogic), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(eqlogic), daiAmt);
    //     eqlogic.deposit(usdcAmt, usdtAmt, daiAmt);
    //     vm.stopPrank();

    //     assertEq(usdcAmt-tBillAmt, IERC20Helper(USDC).balanceOf(address(eqlogic)));
    //     assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(address(loanManager)));
    //     assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(eqlogic)));
    //     assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(eqlogic)));

    //     assertEq(usdcAmt+usdtAmt+daiAmt, nstblToken.balanceOf(user1));

    // }

    // function test_fixed_deposit_fuzz_prices(int256 _price1, int256 _price2, int256 _price3) external {
    //     _price1 = bound(_price1, 97e6, 1e8);
    //     _price2 = bound(_price2, 97e6, 1e8);
    //     _price3 = bound(_price3, 97e6, 1e8);

    //     usdcPriceFeedMock.updateAnswer(_price1);
    //     usdtPriceFeedMock.updateAnswer(_price2);
    //     daiPriceFeedMock.updateAnswer(_price2);

    //     uint256 usdcAmt;
    //     uint256 usdtAmt;
    //     uint256 daiAmt;
    //     uint256 tBillAmt;

    //     if(_price1 <= int256(eqlogic.dt()))
    //         vm.expectRevert("VAULT: Deposits Halted");
    //     (usdcAmt, usdtAmt, daiAmt, tBillAmt) = eqlogic.previewDeposit(1e6);
    //     console.log("usdcAmt: ", usdcAmt);
    //     console.log("usdtAmt: ", usdtAmt);
    //     console.log("daiAmt: ", daiAmt);

    //     deal(USDC, user1, usdcAmt);
    //     deal(USDT, user1, usdtAmt);
    //     deal(DAI, user1, daiAmt);

    //     vm.startPrank(user1);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(eqlogic), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(eqlogic), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(eqlogic), daiAmt);

    //     console.log("allowance", IERC20Helper(USDT).allowance(user1, address(eqlogic)));
    //     if(usdcAmt+usdtAmt+daiAmt == 0)
    //         vm.expectRevert("HUB::Invalid Deposit");
    //     eqlogic.deposit(usdcAmt, usdtAmt, daiAmt);
    //     vm.stopPrank();

    // }

    // function testUSDT_transfer() external {
    //     deal(USDT, user1, 1e6 * 1e6);

    //     vm.startPrank(user1);
    //     IERC20Helper(USDT).safeDecreaseAllowance(address(this), 0);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(this), 1e6 * 1e6);
    //     vm.stopPrank();

    //     IERC20Helper(USDT).safeTransferFrom(user1, address(this), 1e6 * 1e6);
    // }


    /*//////////////////////////////////////////////////////////////
                        TEST INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    // function test_getAllocation() external{
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(985e5);
    //     (uint256 a1, uint256 a2, uint256 a3) = eqLogicHarness.getSystemAllocation();
    //     assertEq(a1, 8e3);
    //     assertEq(a2, 1e3);
    //     assertEq(a3, 1e3);
    // }

    // function test_getAllocation_fuzz(int256 _p1, int256 _p2, int256 _p3) external {
    //     _p1 = bound(_p1, 97e6, 1e8);
    //     _p2 = bound(_p2, 97e6, 1e8);
    //     _p3 = bound(_p3, 97e6, 1e8);

    //     usdcPriceFeedMock.updateAnswer(_p1);
    //     usdtPriceFeedMock.updateAnswer(_p2);
    //     daiPriceFeedMock.updateAnswer(_p3);

    //     int256 dt = int256(eqLogicHarness.dt());
    //     if(_p1<=dt){
    //         vm.expectRevert("VAULT: Deposits Halted");
    //     }
    //     (uint256 a1, uint256 a2, uint256 a3) = eqLogicHarness.getSystemAllocation();
    //     if(_p1>dt){
    //         if (_p2 > dt && _p3 > dt) {
    //             assertEq(a1, 8e3);
    //             assertEq(a2, 1e3);
    //             assertEq(a3, 1e3);
    //         } else if (_p2 > dt && _p3 < dt) {
    //             assertEq(a1, 85e2);
    //             assertEq(a2, 15e2);
    //             assertEq(a3, 0);
    //         } else if (_p2 < dt && _p3 > dt) {
    //             assertEq(a1, 85e2);
    //             assertEq(a2, 0);
    //             assertEq(a3, 15e2);
    //         } else {
    //             assertEq(a1, 10e3);
    //             assertEq(a2, 0);
    //             assertEq(a3, 0);
    //         }
    //     }
    // }

    // function test_calculateEquilibrium_fuzz() external {

    //     // cr1 = bound(cr1, 0, type(uint256).max-1);
    //     // cr2 = bound(cr2, 0, type(uint256).max-1);
    //     // cr3 = bound(cr3, 0, type(uint256).max-1);
    //     // uint256 boundEq = (eqLogicHarness.modSub(cr1) + eqLogicHarness.modSub(cr2) + eqLogicHarness.modSub(cr3))/3;
    //     // boundEq = bound(boundEq, 0, type(uint256).max-1);

    //     // vm.assume(boundEq < type(uint256).max-1);

    //     // uint256 eq = eqLogicHarness.calculateEquilibrium(cr1, cr2, cr3);
    //     uint256 eq = ((1.265e38-1e18) + 1e18 + (1.157e77-1e18)) / 3;
        
    //     console.log("Eq: ", eq);
    // }

    function test_validateAllocation_fuzz(int256 _p1, int256 _p2, int256 _p3, uint256 _amt1, uint256 _amt2) external {
        _p1 = bound(_p1, 97e6, 1e8);
        _p2 = bound(_p2, 979e5, 1e8);
        _p3 = bound(_p3, 987e5, 1e8);

        usdcPriceFeedMock.updateAnswer(_p1);
        usdtPriceFeedMock.updateAnswer(_p2);
        daiPriceFeedMock.updateAnswer(_p3);

        int256 dt = int256(eqLogicHarness.dt());
        bool flag;
        if(_p1<=dt){
            vm.expectRevert("VAULT: Deposits Halted");
            flag = true;
        }
        else if(_p2<=dt){
            vm.expectRevert("VAULT: Invalid Deposit");
            flag = true;
        }
        else if(_p3<=dt){
            vm.expectRevert("VAULT: Invalid Deposit");
            flag = true;
        }
        (uint256 a1, uint256 a2, uint256 a3) = eqLogicHarness.validateSystemAllocation(_amt1, _amt2);
        if(_p1>dt && !flag){
            if (_p2 > dt && _p3 > dt) {
                assertEq(a1, 8e3);
                assertEq(a2, 1e3);
                assertEq(a3, 1e3);
            } else if (_p2 > dt && _p3 < dt) {
                assertEq(a1, 85e2);
                assertEq(a2, 15e2);
                assertEq(a3, 0);
            } else if (_p2 < dt && _p3 > dt) {
                assertEq(a1, 85e2);
                assertEq(a2, 0);
                assertEq(a3, 15e2);
            } else {
                assertEq(a1, 10e3);
                assertEq(a2, 0);
                assertEq(a3, 0);
            }
        }
    }

}