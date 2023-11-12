pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Helper, BaseTest, ERC20 } from "../helpers/BaseTest.t.sol";

contract testProxy is BaseTest{

    function setUp() public override {
        super.setUp();
    }
    function test_proxy_loanManager() external{
        assertEq(loanManager.aclManager(), address(aclManager));
        assertEq(loanManager.nstblHub(), address(nstblHub));
        assertEq(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.MAPLE_POOL_MANAGER_USDC(), MAPLE_POOL_MANAGER_USDC);
        assertEq(loanManager.MAPLE_WITHDRAWAL_MANAGER_USDC(), WITHDRAWAL_MANAGER_USDC);
        assertEq(uint256(vm.load(address(loanManager), bytes32(uint256(0)))), 111);
        assertEq(loanManager.getVersion(), 111);
        assertEq(loanManager.versionSlot(), 111);
        assertEq(ERC20(address(loanManager.lUSDC())).name(), "Loan Manager USDC");
    }
}
contract NSTBLHubTestDeposit is BaseTest {
    using SafeERC20 for IERC20Helper;

    function setUp() public override {
        super.setUp();
    }

    function test_deposit_noDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        // loanManager.updateInvestedAssets(7e5 * 1e18);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);
        console.log("usdcAmt: ", usdcAmt);
        console.log("usdtAmt: ", usdtAmt);
        console.log("daiAmt: ", daiAmt);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM, "idhr fata h");
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    function test_deposit_usdcDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(980e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        // loanManager.updateInvestedAssets(7e5 * 1e18);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;
        vm.expectRevert("HUB: Invalid Deposit");
        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        vm.expectRevert("HUB: Invalid Deposit");
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

        vm.stopPrank();

    }

    function test_deposit_usdtDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(979e5);
        daiPriceFeedMock.updateAnswer(985e5);

        // loanManager.updateInvestedAssets(7e5 * 1e18);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);
        console.log("usdcAmt: ", usdcAmt);
        console.log("usdtAmt: ", usdtAmt);
        console.log("daiAmt: ", daiAmt);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    function test_deposit_daiDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(991e5);
        daiPriceFeedMock.updateAnswer(980e5);

        // loanManager.updateInvestedAssets(7e5 * 1e18);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);
        console.log("usdcAmt: ", usdcAmt);
        console.log("usdtAmt: ", usdtAmt);
        console.log("daiAmt: ", daiAmt);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    function test_fixed_deposit_fuzz_prices(int256 _price1, int256 _price2, int256 _price3) external {
        _price1 = bound(_price1, 97e6, 1e8);
        _price2 = bound(_price2, 97e6, 1e8);
        _price3 = bound(_price3, 97e6, 1e8);

        usdcPriceFeedMock.updateAnswer(_price1);
        usdtPriceFeedMock.updateAnswer(_price2);
        daiPriceFeedMock.updateAnswer(_price2);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        if (_price1 <= int256(nstblHub.dt())) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

        if (usdcAmt + usdtAmt + daiAmt == 0) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

        vm.stopPrank();
        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    function test_deposit_fuzz_depositAmount(uint256 _amount1) external {
        _amount1 = bound(_amount1, 0, 1e9);
        usdcPriceFeedMock.updateAnswer(981e5);
        usdtPriceFeedMock.updateAnswer(981e5);
        daiPriceFeedMock.updateAnswer(981e5);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(_amount1);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

        if (usdcAmt + usdtAmt + daiAmt == 0) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

        vm.stopPrank();
        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    function test_fixed_deposit_fuzz_pricesAndDepositAmount(
        int256 _price1,
        int256 _price2,
        int256 _price3,
        uint256 _amount
    ) external {
        _price1 = bound(_price1, 97e6, 1e8);
        _price2 = bound(_price2, 97e6, 1e8);
        _price3 = bound(_price3, 97e6, 1e8);
        _amount = bound(_amount, 0, 1e9);

        usdcPriceFeedMock.updateAnswer(_price1);
        usdtPriceFeedMock.updateAnswer(_price2);
        daiPriceFeedMock.updateAnswer(_price2);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        if (_price1 <= int256(nstblHub.dt())) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(_amount);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

        if (usdcAmt + usdtAmt + daiAmt == 0) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);


        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

        vm.stopPrank();
        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }
}
contract NSTBLHubTestStakePool is BaseTest {

    function setUp() public override {
        super.setUp();
    }
    
    function test_stake() external {
        //preConditions

        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        address stakePoolLP = address(stakePool.lpToken());
        uint256 lpBalBefore = IERC20Helper(stakePoolLP).balanceOf(destinationAddress);

        //actions
        _depositNSTBL(3e6 * 1e18);
        stakePool.updateMaturityValue();
        _stakeNSTBL(user1, 1e6*1e18, 0);
        _stakeNSTBL(user2, 1e6*1e18, 1);

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(2e6*1e18, nstblToken.balanceOf(address(stakePool)));
        assertEq(1e6*1e18, nstblToken.balanceOf(nealthyAddr));
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress) - lpBalBefore, 2e6*1e18);

        (uint256 amount, uint256 poolDebt, , uint256 lpTokens,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, 1e6*1e18);
        assertEq(poolDebt, 1e18);
        assertEq(lpTokens, 1e6*1e18);
        assertEq(stakePool.poolBalance(), 2e6*1e18);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6*1e18, 0);
        (amount, poolDebt, , lpTokens,) = stakePool.getStakerInfo(user1, 0);
        
        assertEq(lpTokens, 2e6*1e18);
        assertEq(stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)), 3e6*1e18 + (loanManager.getMaturedAssets()-maturityVal));


    }

    function test_stake_fuzz(uint256 _amount) external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        _amount = bound(_amount, 100 , tBillInvestUB*100/(1e6*70));
        _amount *= 1e18;
        address stakePoolLP = address(stakePool.lpToken());
        uint256 lpBalBefore = IERC20Helper(stakePoolLP).balanceOf(destinationAddress);

        //actions
        _depositNSTBL(_amount);
        stakePool.updateMaturityValue();
        _stakeNSTBL(user1, _amount/2, 0); //user1 users _amount/2
        _stakeNSTBL(user2, _amount/4, 1); //user2 users _amount/4

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(3*_amount/4, stakePool.poolBalance(), "check pool Balance");
        assertEq(_amount/4, nstblToken.balanceOf(nealthyAddr), "check remaining nstbl balance");
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress) - lpBalBefore, 3*_amount/4, "check LP balance");

        (uint256 amount, uint256 poolDebt, , uint256 lpTokens,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, _amount/2);
        assertEq(poolDebt, 1e18);
        assertEq(lpTokens, _amount/2);

        vm.warp(block.timestamp + 30 days);

        //restaking
        console.log("Balance before restaking: ", nstblToken.balanceOf(nealthyAddr), _amount/4);
        _stakeNSTBL(user1, _amount/4, 0);
        (amount, poolDebt, , lpTokens,) = stakePool.getStakerInfo(user1, 0);
        
        assertEq(lpTokens, 3*_amount/4);
        if((loanManager.getMaturedAssets()-maturityVal)>1e18){
            assertEq(stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)), _amount + (loanManager.getMaturedAssets()-maturityVal));
        }
        else{
            assertEq(stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)), _amount);

        }


    }

    function test_unstake_noDepeg() external {

        //preConditions
         // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        address stakePoolLP = address(stakePool.lpToken());
        uint256 lpBalBefore = IERC20Helper(stakePoolLP).balanceOf(destinationAddress);

        //actions
        _depositNSTBL(3e6 * 1e18);
        stakePool.updateMaturityValue();
        _stakeNSTBL(user1, 1e6*1e18, 0);
        _stakeNSTBL(user2, 1e6*1e18, 1);

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        (uint256 amount, uint256 poolDebt, , uint256 lpTokens,) = stakePool.getStakerInfo(user1, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6*1e18, 0);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 nealthyBalBefore = nstblToken.balanceOf(nealthyAddr);
        ( amount, , , ,) = stakePool.getStakerInfo(user1, 0);

        //action
        _unstakeNSTBL(user1, 0);
        (uint256 amount2, , , ,) = stakePool.getStakerInfo(user1, 0);
        uint256 nealthyBalAfter = nstblToken.balanceOf(nealthyAddr);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

        //postConditions
        assertEq(amount2, 0);
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 1e6*1e18);
        assertEq(nealthyBalAfter - nealthyBalBefore + (atvlBalAfter-atvlBalBefore), amount);
    }

    function test_unstake_noDepeg_fuzz(uint256 _amount, uint256 _time) external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        _amount = bound(_amount, 100 , tBillInvestUB*100/(1e6*70));
        _amount *= 1e18;
        _time = bound(_time, 0, 365 days);
        address stakePoolLP = address(stakePool.lpToken());
        uint256 lpBalBefore = IERC20Helper(stakePoolLP).balanceOf(destinationAddress);

        //actions
        _depositNSTBL(_amount);
        stakePool.updateMaturityValue();
        uint256 oldMaturityVal = stakePool.oldMaturityVal();
        _stakeNSTBL(user1, _amount/2, 0); //user1 users _amount/2
        _stakeNSTBL(user2, _amount/4, 1); //user2 users _amount/4

        //time warp
        vm.warp(block.timestamp + _time);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        //restaking
        _stakeNSTBL(user1, _amount/4, 0);


        uint256 nealthyBalBefore = nstblToken.balanceOf(nealthyAddr);
        ( uint256 amount, , , ,) = stakePool.getStakerInfo(user1, 0);
        ( uint256 amount3, , , ,) = stakePool.getStakerInfo(user2, 1);

        //action
        _unstakeNSTBL(user1, 0);
        _unstakeNSTBL(user2, 1);

        //postConditions
        (uint256 amount2, , , ,) = stakePool.getStakerInfo(user1, 0);
        uint256 nealthyBalAfter = nstblToken.balanceOf(nealthyAddr);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

         assertEq(amount2, 0);
        if ((loanManager.getMaturedAssets() - oldMaturityVal) > 1e18) {
            assertApproxEqAbs(
                nealthyBalAfter - nealthyBalBefore + (atvlBalAfter - atvlBalBefore),
                _amount + (loanManager.getMaturedAssets() - oldMaturityVal),
                1e18,
                "with yield"
            );
        } else {
            assertEq(nealthyBalAfter - nealthyBalBefore + (atvlBalAfter - atvlBalBefore), _amount, "without yield");
        }
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 0);


    }
}

// contract NSTBLHubTestUnstake is BaseTest {

//     function setUp() public override {
//         super.setUp();
//     }

//     function test_unstake_OneDepeg_InsuffLiquidity() external {
//         erc20_transfer(address(nstblToken), admin, address(atvl), 12_000 * 1e18);
//         uint256 _amount = 1e6 * 1e18;
//         _stakeNstbl(nealthyAddr, _amount, 0);

//         //maintaining exact proportions
//         deal(USDC, address(nstblHub), 8e5 * 1e6);
//         deal(USDT, address(nstblHub), 1e5 * 1e6);
//         deal(DAI, address(nstblHub), 1e5 * 1e18);

//         usdcPriceFeedMock.updateAnswer(981e5);
//         usdtPriceFeedMock.updateAnswer(99e6);
//         daiPriceFeedMock.updateAnswer(975e5);

//         vm.expectRevert("HUB::UNAUTH");
//         nstblHub.unstake(0, nealthyAddr);

//         uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyBefore = nstblToken.totalSupply();
//         uint256 nealthyBalBefore = nstblToken.balanceOf(nealthyAddr);

//         vm.startPrank(nealthyAddr);
//         nstblHub.unstake(0, nealthyAddr);
//         vm.stopPrank();

//         uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyAfter = nstblToken.totalSupply();
//         uint256 nealthyBalAfter = nstblToken.balanceOf(nealthyAddr);

//         assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
//         // assertEq(nstblSupplyBefore - nstblSupplyAfter, 1e23);
//     }

//     function test_unstake_TwoDepeg_InsuffLiquidity() external {

//         erc20_transfer(address(nstblToken), admin, address(atvl), 12_000 * 1e18);
//         uint256 _amount = 1e6 * 1e18;
//         _stakeNstbl(nealthyAddr, _amount, 0);

//         //maintaining exact proportions
//         deal(USDC, address(nstblHub), 8e5 * 1e6);
//         deal(USDT, address(nstblHub), 1e5 * 1e6);
//         deal(DAI, address(nstblHub), 1e5 * 1e18);

//         usdcPriceFeedMock.updateAnswer(981e5);
//         usdtPriceFeedMock.updateAnswer(975e5);
//         daiPriceFeedMock.updateAnswer(965e5);

//         vm.expectRevert("HUB::UNAUTH");
//         nstblHub.unstake(0, nealthyAddr);

//         uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyBefore = nstblToken.totalSupply();
//         uint256 stakeAmountBefore = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         vm.startPrank(nealthyAddr);
//         nstblHub.unstake(0, nealthyAddr);
//         vm.stopPrank();

//         uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyAfter = nstblToken.totalSupply();
//         uint256 stakeAmountAfter = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
//         // assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
//     }

//     function test_unstake_ThreeDepeg_InsuffLiquidity() external {
//         erc20_transfer(address(nstblToken), admin, address(atvl), 100_000 * 1e18);
//         uint256 _amount = 1e6 * 1e18;
//         _stakeNstbl(nealthyAddr, _amount, 0);

//         //maintaining exact proportions
//         deal(USDC, address(nstblHub), 8e5 * 1e6);
//         deal(USDT, address(nstblHub), 1e5 * 1e6);
//         deal(DAI, address(nstblHub), 1e5 * 1e18);

//         usdcPriceFeedMock.updateAnswer(959e5);
//         usdtPriceFeedMock.updateAnswer(975e5);
//         daiPriceFeedMock.updateAnswer(965e5);

//         vm.expectRevert("HUB::UNAUTH");
//         nstblHub.unstake(0, nealthyAddr);

//         uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyBefore = nstblToken.totalSupply();
//         uint256 stakeAmountBefore = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         vm.startPrank(nealthyAddr);
//         nstblHub.unstake(0, nealthyAddr);
//         vm.stopPrank();

//         uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyAfter = nstblToken.totalSupply();
//         uint256 stakeAmountAfter = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
//         // assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
//     }

//     function test_unstake_ThreeDepeg_SuffLiquidity() external {
//         erc20_transfer(address(nstblToken), admin, address(atvl), 100_000 * 1e18);
//         uint256 _amount = 1e6 * 1e18;
//         _stakeNstbl(nealthyAddr, _amount, 0);

//         //maintaining exact proportions
//         deal(USDC, address(nstblHub), 800e5 * 1e6);
//         deal(USDT, address(nstblHub), 1e5 * 1e6);
//         deal(DAI, address(nstblHub), 1e5 * 1e18);

//         usdcPriceFeedMock.updateAnswer(959e5);
//         usdtPriceFeedMock.updateAnswer(975e5);
//         daiPriceFeedMock.updateAnswer(965e5);

//         vm.expectRevert("HUB::UNAUTH");
//         nstblHub.unstake(0, nealthyAddr);

//         uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalBefore = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyBefore = nstblToken.totalSupply();
//         uint256 stakeAmountBefore = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         vm.startPrank(nealthyAddr);
//         nstblHub.unstake(0, nealthyAddr);
//         vm.stopPrank();

//         uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));
//         uint256 stakePoolBalAfter = nstblToken.balanceOf(address(stakePool));
//         uint256 nstblSupplyAfter = nstblToken.totalSupply();
//         uint256 stakeAmountAfter = stakePool.getUserStakedAmount(nealthyAddr, 0);

//         assertEq(atvlBalBefore - atvlBalAfter + atvl.pendingNstblBurn(), nstblHub.atvlBurnAmount());
//         // assertEq(nstblSupplyBefore - nstblSupplyAfter, nstblHub.atvlBurnAmount() + stakeAmountBefore - stakeAmountAfter);
//     }
// }

contract NSTBLHubTestRedeem is BaseTest {
    using SafeERC20 for IERC20Helper;

    function setUp() public override {
        super.setUp();
    }

    function test_redeem_noDepeg_suffLiquidity() external {

        uint256 _amount = 1e6 * 1e18;

        //noDepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //first making a deposit
        (uint256 usdcAmt, uint256 usdtAmt, uint256 daiAmt, uint256 tBillAmt) = nstblHub.previewDeposit(1e6);
        console.log("usdcAmt: ", usdcAmt);
        console.log("usdtAmt: ", usdtAmt);
        console.log("daiAmt: ", daiAmt);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();
        assertEq(nstblBalAfter - nstblBalBefore, _amount);
        //deposited

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);
        //can redeem only 12.5% of the liquidity
        nstblHub.redeem(125*_amount/1000, user1);
        vm.stopPrank();
        uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
        nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        //redeemed only 12.5% of the liquidity
        assertEq((_amount*1/10)/10**12, usdcBalBefore - usdcBalAfter);
        assertEq((_amount*125/10000)/10**12, usdtBalBefore - usdtBalAfter);
        assertEq((_amount*125/10000), daiBalBefore - daiBalAfter);
        //usdc should've been drained from the hub
        assertEq(usdcBalAfter, 0);

        assertEq(125*_amount/1000, nstblBalBefore - nstblBalAfter); //burned tokens from the user

        //checking for T-bill redemption status
        assertTrue(loanManager.awaitingRedemption());

        vm.startPrank(nealthyAddr);
        vm.expectRevert("LM: Not in Window");
        uint256 stablesRedeemed = nstblHub.processTBillWithdraw();
        console.log("stables redeemed: ", stablesRedeemed);

        (uint256 windowStart, ) = loanManager.getRedemptionWindow();
        vm.warp(windowStart);
        stablesRedeemed = nstblHub.processTBillWithdraw();
        console.log("stables redeemed: ", stablesRedeemed);

        assertEq(stablesRedeemed, IERC20Helper(USDC).balanceOf(address(nstblHub)));
        console.log("Hub USDT balance after redemption: ", IERC20Helper(USDT).balanceOf(address(nstblHub)));
        console.log("Hub DAI balance after redemption: ", IERC20Helper(DAI).balanceOf(address(nstblHub)));

    }

    function test_redeem_noDepeg_suffLiquidity_fuzz(uint256 _amount) external {
        
        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        console.log("tBillInvestUB: ", tBillInvestUB, tBillInvestUB*1e12*100/70);
        _amount = bound(_amount, 100 * 1e18, tBillInvestUB*1e12*100/70); //issue with very small values- test tomorrow

        // uint256 _amount = 1e6 * 1e18;

        //noDepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //first making a deposit
        (uint256 usdcAmt, uint256 usdtAmt, uint256 daiAmt,) = nstblHub.previewDeposit(_amount/1e18);
        // console.log("usdcAmt: ", usdcAmt);
        // console.log("usdtAmt: ", usdtAmt);
        // console.log("daiAmt: ", daiAmt);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();
        // assertEq(nstblBalAfter - nstblBalBefore, _amount);
        //deposited

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);
        //can redeem only 12.5% of the liquidity
        nstblHub.redeem(124*_amount/1000, user1);
        vm.stopPrank();
        
        nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        //redeemed only 12.5% of the liquidity
        assertEq((_amount*992/10000)/10**12, usdcBalBefore - IERC20Helper(USDC).balanceOf(address(nstblHub)),  "check USDC balance");
        assertEq((_amount*124/10000)/10**12, usdtBalBefore - IERC20Helper(USDT).balanceOf(address(nstblHub)), "check USDT balance");
        assertEq((_amount*124/10000), daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub)), "check DAI balance");
        //usdc should've been drained from the hub
        assertApproxEqAbs(IERC20Helper(USDC).balanceOf(address(nstblHub)), (_amount/1e12)*8/10000, 1e5, "check USDC balance fromHub");

        assertEq(124*_amount/1000, nstblBalBefore - nstblBalAfter); //burned tokens from the user

        // //checking for T-bill redemption status
        // assertTrue(loanManager.awaitingRedemption());

        // vm.startPrank(nealthyAddr);
        // vm.expectRevert("LM: Not in Window");
        // uint256 stablesRedeemed = nstblHub.processTBillWithdraw();
        // console.log("stables redeemed: ", stablesRedeemed);

        // (uint256 windowStart, ) = loanManager.getRedemptionWindow();
        // vm.warp(windowStart);
        // stablesRedeemed = nstblHub.processTBillWithdraw();
        // console.log("stables redeemed: ", stablesRedeemed);

        // assertEq(stablesRedeemed, IERC20Helper(USDC).balanceOf(address(nstblHub)));
        // console.log("Hub USDT balance after redemption: ", IERC20Helper(USDT).balanceOf(address(nstblHub)));
        // console.log("Hub DAI balance after redemption: ", IERC20Helper(DAI).balanceOf(address(nstblHub)));

    }

    // function test_redeem_daiAtDepeg_suffLiquidity() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(980e5);

    //     deal(USDC, address(nstblHub), (_amount*8/10)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*1/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*1/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
    //     assertEq((_amount*8/10)/10**12, usdcBalBefore - usdcBalAfter);
    //     assertEq((_amount*1/10)/10**12, usdtBalBefore - usdtBalAfter);
    //     assertEq((_amount*1/10), daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter);

    // }

    // function test_redeem_daiDepeg_suffLiquidity() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(970e5);

    //     deal(USDC, address(nstblHub), (_amount*8/10)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*1/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*2/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
    //     assertEq((_amount*8/10)/10**12, usdcBalBefore - usdcBalAfter);
    //     assertEq((_amount*1/10)/10**12, usdtBalBefore - usdtBalAfter);
    //     uint256 finalDaiBal = (_amount*1/10)*nstblHub.dt()/97e6;
    //     assertEq(finalDaiBal, daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter);

    // }

    // function test_redeem_daiUSDTDepeg_suffLiquidity() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(975e5);
    //     daiPriceFeedMock.updateAnswer(970e5);

    //     deal(USDC, address(nstblHub), (_amount*8/10)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*2/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*2/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
    //     assertEq((_amount*8/10)/10**12, usdcBalBefore - usdcBalAfter);
    //     uint256 finalUsdtBal = ((_amount*1/10)/10**12)*nstblHub.dt()/975e5;
    //     assertEq(finalUsdtBal, usdtBalBefore - usdtBalAfter);
    //     uint256 finalDaiBal = (_amount*1/10)*nstblHub.dt()/97e6;
    //     assertEq(finalDaiBal, daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter);

    // }

    // function test_redeem_daiUSDTDepeg_suffLiquidity_case2() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(975e5);
    //     daiPriceFeedMock.updateAnswer(970e5);

    //     deal(USDC, address(nstblHub), (_amount)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*1/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*1/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

    //     uint256 daiRedeemableNSTBL = (_amount*1/10)/1e12*97e6/nstblHub.dt();
    //     uint256 usdtRedeemableNSTBL = ((_amount*1/10)/10**12)*975e5/nstblHub.dt();

    //     assertTrue((_amount*8/10)/10**12 + ((_amount*1/10)/1e12 - daiRedeemableNSTBL) + ((_amount*1/10)/10**12 - usdtRedeemableNSTBL) - (usdcBalBefore - usdcBalAfter)<10);
    //     assertEq(((_amount*1/10)/10**12), usdtBalBefore - usdtBalAfter);
    //     assertEq((_amount*1/10), daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter );

    // }

    // function test_redeem_daiUSDTDepeg_insuffLiquidity() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(975e5);
    //     daiPriceFeedMock.updateAnswer(970e5);

    //     deal(USDC, address(nstblHub), (_amount*8/10)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*1/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*1/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

    //     uint256 daiRedeemableNSTBL = (_amount*1/10)/1e12*97e6/nstblHub.dt();
    //     uint256 usdtRedeemableNSTBL = ((_amount*1/10)/10**12)*975e5/nstblHub.dt();

    //     assertEq((_amount*8/10)/10**12 , (usdcBalBefore - usdcBalAfter));
    //     assertEq(((_amount*1/10)/10**12), usdtBalBefore - usdtBalAfter);
    //     assertEq((_amount*1/10), daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter );
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblHub.atvlBurnAmount());

    // }

    // function test_redeem_usdcDepeg_suffLiquidity() external {

    //     uint256 _amount = 1e6*1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(975e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(980e5);

    //     deal(USDC, address(nstblHub), (_amount)/10**12);
    //     deal(USDT, address(nstblHub), (_amount*1/10)/10**12);
    //     deal(DAI, address(nstblHub), (_amount*1/10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
    //     uint256 usdcWithdrawAmt = (_amount*8/10)/10**12 * nstblHub.dt()/975e5;
    //     assertEq(usdcWithdrawAmt, usdcBalBefore - usdcBalAfter);
    //     assertEq((_amount*1/10)/10**12, usdtBalBefore - usdtBalAfter);
    //     assertEq((_amount*1/10), daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter);

    // }

    // function test_redeem_daiUSDTDepeg_belowLB_suffLiquidity() external {
    //     uint256 _amount = 1e6 * 1e18;
    //     erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);

    //     //daiDepeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(955e5);
    //     daiPriceFeedMock.updateAnswer(950e5);

    //     deal(USDC, address(nstblHub), (_amount * 8 / 10) / 10 ** 12);
    //     deal(USDT, address(nstblHub), (_amount * 2 / 10) / 10 ** 12);
    //     deal(DAI, address(nstblHub), (_amount * 2 / 10));

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);
    //     nstblHub.redeem(_amount, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

    //     uint256 daiRedeemableAmt = (_amount * 1 / 10) * nstblHub.dt() / 950e5;
    //     uint256 usdtRedeemableAmt = ((_amount * 1 / 10) / 10 ** 12) * nstblHub.dt() / 955e5;

    //     assertEq((_amount * 8 / 10) / 10 ** 12, (usdcBalBefore - usdcBalAfter));
    //     assertEq(usdtRedeemableAmt, usdtBalBefore - usdtBalAfter);
    //     assertEq(daiRedeemableAmt, daiBalBefore - daiBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblBalBefore - nstblBalAfter);
    //     assertEq(nstblToken.balanceOf(address(nstblHub)), nstblHub.atvlBurnAmount());
    // }
}

// contract NSTBLHubInternal is BaseTest{

//     function setUp() public override {
//         super.setUp();
//     }

// function test_getAllocation() external {
//     usdcPriceFeedMock.updateAnswer(982e5);
//     usdtPriceFeedMock.updateAnswer(99e6);
//     daiPriceFeedMock.updateAnswer(985e5);
//     (uint256 a1, uint256 a2, uint256 a3) = nstblHubHarness.getSystemAllocation();
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

//     int256 dt = int256(nstblHubHarness.dt());
//     if (_p1 <= dt) {
//         vm.expectRevert("VAULT: Deposits Halted");
//     }
//     (uint256 a1, uint256 a2, uint256 a3) = nstblHubHarness.getSystemAllocation();
//     if (_p1 > dt) {
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

// function test_validateAllocation_fuzz(
//     int256 _p1,
//     int256 _p2,
//     int256 _p3,
//     uint256 _amt1,
//     uint256 _amt2,
//     uint256 _amt3
// ) external {
//     _p1 = bound(_p1, 97e6, 1e8);
//     _p2 = bound(_p2, 979e5, 1e8);
//     _p3 = bound(_p3, 987e5, 1e8);
//     _amt1 = bound(_amt1, 0, (type(uint256).max - 1) / 3);
//     _amt2 = bound(_amt2, 0, (type(uint256).max - 1) / 3);
//     _amt3 = bound(_amt3, 0, (type(uint256).max - 1) / 3);
//     usdcPriceFeedMock.updateAnswer(_p1);
//     usdtPriceFeedMock.updateAnswer(_p2);
//     daiPriceFeedMock.updateAnswer(_p3);

//     int256 dt = int256(nstblHubHarness.dt());
//     bool flag;
//     if (_p1 <= dt) {
//         vm.expectRevert("VAULT: Deposits Halted");
//         flag = true;
//     } else if (_p2 <= dt) {
//         vm.expectRevert("VAULT: Invalid Deposit");
//         flag = true;
//     } else if (_p3 <= dt) {
//         vm.expectRevert("VAULT: Invalid Deposit");
//         flag = true;
//     }
//     (uint256 a1, uint256 a2, uint256 a3) = nstblHubHarness.validateSystemAllocation(_amt1, _amt2, _amt3);
//     if (_p1 > dt && !flag) {
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

// function test_getSortedAssetPrices() external {

//     usdcPriceFeedMock.updateAnswer(999e5);
//     usdtPriceFeedMock.updateAnswer(99e6);
//     daiPriceFeedMock.updateAnswer(985e5);

//     (address[] memory assets, uint256[] memory prices) = nstblHubHarness.getSortedAssetsWithPrice();
//     assertTrue(assets[0] == DAI);
//     assertTrue(assets[1] == USDT);
//     assertTrue(assets[2] == USDC);

//     assertEq(prices[0], 985e5);
//     assertEq(prices[1], 99e6);
//     assertEq(prices[2], 999e5);
// }
// }
