pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Helper, BaseTest, ERC20, NSTBLHub, TransparentUpgradeableProxy } from "../helpers/BaseTest.t.sol";

contract testProxy is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_proxy_loanManager() external {
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

    function test_proxy_hub() external {
        assertEq(nstblHub.nstblToken(), address(nstblToken));
        assertEq(nstblHub.stakePool(), address(stakePool));
        assertEq(nstblHub.chainLinkPriceFeed(), address(priceFeed));
        assertEq(nstblHub.atvl(), address(atvl));
        assertEq(nstblHub.loanManager(), address(loanManager));
        assertEq(nstblHub.aclManager(), address(aclManager));
        assertEq(nstblHub.eqTh(), 2*1e24);
        assertEq(nstblHub.getVersion(), 1);
    }

    function test_proxy_hub_setup() external {
        vm.startPrank(owner);
        NSTBLHub hubImp2 = new NSTBLHub();
        bytes memory data1 = abi.encodeCall(
            nstblHubImpl.initialize,
            (
                address(nstblToken),
                address(stakePool),
                address(priceFeed),
                address(atvl),
                address(loanManager),
                address(aclManager),
                3*1e24
            )
        );
        TransparentUpgradeableProxy proxyNew = new TransparentUpgradeableProxy(address(hubImp2), address(proxyAdmin), data1);
        vm.stopPrank();
        NSTBLHub hub2 = NSTBLHub(address(proxyNew));
        assertEq(hub2.nstblToken(), address(nstblToken));
        assertEq(hub2.stakePool(), address(stakePool));
        assertEq(hub2.eqTh(), 3*1e24);
    }
}

contract testATVL is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_init() external{
        assertEq(atvl.checkDeployedATVL(), 0);
        vm.prank(deployer);
        atvl.init(vm.addr(345));
        assertEq(atvl.nstblToken(), vm.addr(345));

    }

    function test_setAuthorizedCaller() external {
        vm.prank(deployer);
        atvl.setAuthorizedCaller(vm.addr(345), true);
        assertEq(atvl.authorizedCallers(vm.addr(345)), true);
    }
    
}
contract testSetters is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_setSytemParams() external {
        vm.prank(deployer);
        nstblHub.setSystemParams(99e6, 98e6, 97e6, 2e3, 4e3, 2*1e24);
        assertEq(nstblHub.dt(), 99e6);
        assertEq(nstblHub.ub(), 98e6);
        assertEq(nstblHub.lb(), 97e6);
        assertEq(nstblHub.liquidPercent(), 2e3);
        assertEq(nstblHub.tBillPercent(), 4e3);
    }
    function test_updateAllocation() external {
        vm.prank(deployer);
        nstblHub.updateAssetAllocation(USDC, 100);
        assertEq(nstblHub.assetAllocation(USDC), 100);
    }

    function test_updateAssetFeeds() external {
        vm.prank(deployer);
        nstblHub.updateAssetFeeds([address(usdtPriceFeedMock), address(usdcPriceFeedMock), address(daiPriceFeedMock)]);
        assertEq(nstblHub.assetFeeds(0), address(usdtPriceFeedMock));
        assertEq(nstblHub.assetFeeds(1), address(usdcPriceFeedMock));
        assertEq(nstblHub.assetFeeds(2), address(daiPriceFeedMock));
    }
}

contract NSTBLHubTestDeposit is BaseTest {
    using SafeERC20 for IERC20Helper;

    function setUp() public override {
        super.setUp();
    }

    function test_deposit_failing_cases() external {
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(975e5);
        deal(USDC, nealthyAddr, 1e6 * 1e6);
        deal(USDT, nealthyAddr, 1e6 * 1e6);
        deal(DAI, nealthyAddr, 1e6 * 1e18);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e18);
        vm.expectRevert("HUB: Invalid Deposit");
        nstblHub.deposit(1e6 * 1e6, 1e6 * 1e6, 1e6 * 1e6);
        vm.stopPrank();

        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(981e5);
        daiPriceFeedMock.updateAnswer(975e5);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e18);
        vm.expectRevert("HUB: Invalid Deposit");
        nstblHub.deposit(1e6 * 1e6, 1e6 * 1e6, 1e6 * 1e6);
        vm.stopPrank();


    }

    function test_deposit_fail_eqRevert() external {
        
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(985e5);

        vm.prank(deployer);
        nstblHub.setSystemParams(dt, ub, lb, 1e3, 7e3, 0);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;

        (usdcAmt, usdtAmt, daiAmt,) = nstblHub.previewDeposit(1e6);
        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        vm.expectRevert("HUB::Deposit Not Allowed");
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopPrank();
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
        //
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(usdcAmt - tBillAmt, IERC20Helper(USDC).balanceOf(address(nstblHub)) - usdcBalBefore);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM, "idhr fata h");
        assertEq(usdtAmt, IERC20Helper(USDT).balanceOf(address(nstblHub)) - usdtBalBefore);
        assertEq(daiAmt, IERC20Helper(DAI).balanceOf(address(nstblHub)) - daiBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));

        _depositNSTBL(1e6 * 1e18);
        assertEq(nstblToken.totalSupply(), 2e6 * 1e18);
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

    function test_stake_failing() external {
        //preConditions

        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        vm.startPrank(nealthyAddr);
        vm.expectRevert("HUB: STAKE_LIMIT_EXCEEDED");
        nstblHub.stake(user1, 5e6*1e18, 0, destinationAddress);
        vm.stopPrank();

        
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
        _depositNSTBL(10e6 * 1e18);
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(2e6 * 1e18, nstblToken.balanceOf(address(stakePool)));
        assertEq(8e6 * 1e18, nstblToken.balanceOf(nealthyAddr));
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress) - lpBalBefore, 2e6 * 1e18);

        (uint256 amount, uint256 poolDebt,, uint256 lpTokens,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, 1e6 * 1e18);
        assertEq(poolDebt, 1e18);
        assertEq(lpTokens, 1e6 * 1e18);
        assertEq(stakePool.poolBalance(), 2e6 * 1e18);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        (amount, poolDebt,, lpTokens,) = stakePool.getStakerInfo(user1, 0);

        assertEq(lpTokens, 2e6 * 1e18);
        assertEq(
            stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)),
            3e6 * 1e18 + (loanManager.getMaturedAssets() - maturityVal)
        );
    }

    function test_stake_fuzz(uint256 _amount) external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        _amount = bound(_amount, 100, tBillInvestUB * 100 / (1e6 * 70));
        _amount *= 1e18;
        address stakePoolLP = address(stakePool.lpToken());
        uint256 lpBalBefore = IERC20Helper(stakePoolLP).balanceOf(destinationAddress);

        //actions
        _depositNSTBL(_amount);

        uint256 maxStakeAmount = 40 * nstblToken.totalSupply() / 100;
        // maxStakeAmount = 30*maxStakeAmount/100;
        _stakeNSTBL(user1, maxStakeAmount / 2, 0); //user1 users maxStakeAmount/2
        _stakeNSTBL(user2, maxStakeAmount / 4, 1); //user2 users maxStakeAmount/4

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(3 * maxStakeAmount / 4, stakePool.poolBalance(), "check pool Balance");
        assertEq(
            IERC20Helper(stakePoolLP).balanceOf(destinationAddress) - lpBalBefore,
            3 * maxStakeAmount / 4,
            "check LP balance"
        );

        (uint256 amount, uint256 poolDebt,, uint256 lpTokens,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, maxStakeAmount / 2);
        assertEq(poolDebt, 1e18);
        assertEq(lpTokens, maxStakeAmount / 2);

        vm.warp(block.timestamp + 30 days);

        //restaking
        _stakeNSTBL(user1, maxStakeAmount / 4, 0);
        (amount, poolDebt,, lpTokens,) = stakePool.getStakerInfo(user1, 0);

        assertEq(lpTokens, 3 * maxStakeAmount / 4);
        if ((loanManager.getMaturedAssets() - maturityVal) > 1e18) {
            assertEq(
                stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)),
                maxStakeAmount + (loanManager.getMaturedAssets() - maturityVal)
            );
        } else {
            assertEq(stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)), maxStakeAmount);
        }
    }

    function test_unstake_noDepeg() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        address stakePoolLP = address(stakePool.lpToken());

        //actions
        _depositNSTBL(10e6 * 1e18);

        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        (uint256 amount,,,,) = stakePool.getStakerInfo(user1, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 nealthyBalBefore = nstblToken.balanceOf(nealthyAddr);
        (amount,,,,) = stakePool.getStakerInfo(user1, 0);

        //action
        _unstakeNSTBL(user1, 0);
        (uint256 amount2,,,,) = stakePool.getStakerInfo(user1, 0);
        uint256 nealthyBalAfter = nstblToken.balanceOf(nealthyAddr);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

        //postConditions
        assertEq(amount2, 0);
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 1e6 * 1e18);
        assertEq(nealthyBalAfter - nealthyBalBefore + (atvlBalAfter - atvlBalBefore), amount);
    }

    function test_unstake_noDepeg_fuzz(uint256 _amount, uint256 _time) external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        _amount = bound(_amount, 100, tBillInvestUB * 100 / (1e6 * 70));
        _amount *= 1e18;
        _time = bound(_time, 0, 365 days);
        address stakePoolLP = address(stakePool.lpToken());

        //actions
        _depositNSTBL(_amount);

        uint256 oldMaturityVal = stakePool.oldMaturityVal();
        uint256 maxStakeAmount = 40 * nstblToken.totalSupply() / 100;
        _stakeNSTBL(user1, maxStakeAmount / 2, 0); //user1 users maxStakeAmount/2
        _stakeNSTBL(user2, maxStakeAmount / 4, 1); //user2 users maxStakeAmount/4

        //time warp
        vm.warp(block.timestamp + _time);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        //restaking
        _stakeNSTBL(user1, maxStakeAmount / 4, 0);

        uint256 nealthyBalBefore = nstblToken.balanceOf(nealthyAddr);

        //action
        _unstakeNSTBL(user1, 0);
        _unstakeNSTBL(user2, 1);

        //postConditions
        (uint256 amount2,,,,) = stakePool.getStakerInfo(user1, 0);
        uint256 nealthyBalAfter = nstblToken.balanceOf(nealthyAddr);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

        assertEq(amount2, 0);
        if ((loanManager.getMaturedAssets() - oldMaturityVal) > 1e18) {
            assertApproxEqAbs(
                nealthyBalAfter - nealthyBalBefore + (atvlBalAfter - atvlBalBefore),
                maxStakeAmount + (loanManager.getMaturedAssets() - oldMaturityVal),
                1e12,
                "with yield"
            );
        } else {
            assertEq(
                nealthyBalAfter - nealthyBalBefore + (atvlBalAfter - atvlBalBefore), maxStakeAmount, "without yield"
            );
        }
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 0);
    }

    function test_unstake_Depeg() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        address stakePoolLP = address(stakePool.lpToken());

        //actions
        _depositNSTBL(10e6 * 1e18);
        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        (uint256 amount,,,,) = stakePool.getStakerInfo(user1, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);

        (amount,,,,) = stakePool.getStakerInfo(user1, 0);

        //one asset depegs just before unstaking
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(975e5);

        //action
        _unstakeNSTBL(user1, 0);
        assertEq(IERC20Helper(DAI).balanceOf(address(nstblHub)), 0); //all the failing stable is drained
        (uint256 amount2,,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount2, 0);
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 1e6 * 1e18);
    }

    function test_unstake_AllDepeg() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        address stakePoolLP = address(stakePool.lpToken());

        //actions
        _depositNSTBL(10e6 * 1e18);
        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        (uint256 amount,,,,) = stakePool.getStakerInfo(user1, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);

        (amount,,,,) = stakePool.getStakerInfo(user1, 0);

        //all assets depeg just before unstaking
        usdcPriceFeedMock.updateAnswer(979e5);
        usdtPriceFeedMock.updateAnswer(976e5);
        daiPriceFeedMock.updateAnswer(973e5);

        //action
        _unstakeNSTBL(user1, 0);
        assertEq(IERC20Helper(DAI).balanceOf(address(nstblHub)), 0); //all the failing stable is drained
        (uint256 amount2,,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount2, 0);
        assertEq(IERC20Helper(stakePoolLP).balanceOf(destinationAddress), 1e6 * 1e18);
    }

    function test_unstake_Depeg_belowUB() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 1e4 * 1e18, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e4 * 1e18, 0);

        // uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 nstblSupply = nstblToken.totalSupply();
        uint256 unstakeAmt = stakePool.getUserAvailableTokens(user1, 0);

        //one asset depegs just before unstaking
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(968e5);

        uint256 nealthyBalBefore = IERC20Helper(DAI).balanceOf(nealthyAddr);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));

        //action
        _unstakeNSTBL(user1, 0);
        // assertEq(IERC20Helper(DAI).balanceOf(address(nstblHub)), 0); //all the failing stable is drained
        (uint256 amount2,,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount2, 0);
        assertEq(
            IERC20Helper(DAI).balanceOf(nealthyAddr) - nealthyBalBefore,
            daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub))
        );
        assertEq(
            nstblSupply - nstblToken.totalSupply(), unstakeAmt + (atvlBalBefore - nstblToken.balanceOf(address(atvl)))
        );
    }
}

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
        _depositNSTBL(_amount);

        vm.startPrank(nealthyAddr);
        vm.expectRevert("HUB: No redemption requested");
        nstblHub.processTBillWithdraw();
        vm.stopPrank();

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);
        //can redeem only 12.5% of the liquidity
        nstblHub.redeem(125 * _amount / 1000, user1);
        vm.stopPrank();
        uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        //redeemed only 12.5% of the liquidity
        assertEq((_amount * 1 / 10) / 10 ** 12, usdcBalBefore - usdcBalAfter);
        assertEq((_amount * 125 / 10_000) / 10 ** 12, usdtBalBefore - usdtBalAfter);
        assertEq((_amount * 125 / 10_000), daiBalBefore - daiBalAfter);
        //usdc should've been drained from the hub
        assertEq(usdcBalAfter, 0);

        assertEq(125 * _amount / 1000, nstblBalBefore - nstblBalAfter); //burned tokens from the user

        //checking for T-bill redemption status
        assertTrue(loanManager.awaitingRedemption());

        vm.startPrank(nealthyAddr);
        vm.expectRevert("LM: Not in Window");
        uint256 stablesRedeemed = nstblHub.processTBillWithdraw();

        (uint256 windowStart,) = loanManager.getRedemptionWindow();
        vm.warp(windowStart);
        stablesRedeemed = nstblHub.processTBillWithdraw();

        assertEq(stablesRedeemed, IERC20Helper(USDC).balanceOf(address(nstblHub)));
    }

    function test_redeem_noDepeg_insuffLiquidity() external {
        //noDepeg
        usdcPriceFeedMock.updateAnswer(992e5);
        usdtPriceFeedMock.updateAnswer(981e5);
        daiPriceFeedMock.updateAnswer(975e5);

        _depositNSTBL(1e6*1e18);

        //first making a deposit
        deal(address(nstblToken), nealthyAddr, 1e6 * 1e18);
        deal(USDC, address(nstblHub), 1e6 * 1e6);
        deal(USDT, address(nstblHub), 5e3 * 1e6);
        deal(DAI, address(nstblHub), 5e3 * 1e18);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        vm.startPrank(nealthyAddr);
        nstblHub.redeem(1e6*1e18, user1);

        assertEq(IERC20Helper(USDT).balanceOf(address(nstblHub)), 0);
        assertEq(IERC20Helper(DAI).balanceOf(address(nstblHub)), 0);

    }

    function test_redeem_daiDepeg_suffLiquidity() external {
        uint256 _amount = 1e6 * 1e18;

        //noDepeg at the time of depeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(981e5);

        //first making a deposit
        _depositNSTBL(_amount);
        deal(address(nstblToken), address(atvl), _amount * 2 / 100); //2% of the total supply
        assertEq(nstblToken.balanceOf(address(atvl)), _amount * 2 / 100);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));

        vm.startPrank(nealthyAddr);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(975e5);

        //redeeming 10% of the liquidity

        nstblHub.redeem(10 * _amount / 100, user1);
        vm.stopPrank();
        //redeemed only 10% of the liquidity
        assertEq(
            (_amount * 8 / 100) / 10 ** 12,
            usdcBalBefore - IERC20Helper(USDC).balanceOf(address(nstblHub)),
            "check USDC balance"
        );
        assertEq(
            (_amount * 1 / 100) / 10 ** 12,
            usdtBalBefore - IERC20Helper(USDT).balanceOf(address(nstblHub)),
            "check USDT balance"
        );
        assertEq(
            (_amount * 1 / 100) * 980e5 / 975e5,
            daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub)),
            "check DAI balance"
        );
        assertEq(
            atvlBalBefore - nstblToken.balanceOf(address(atvl)),
            ((_amount * 1 / 100) * 980e5 / 975e5) - (_amount * 1 / 100),
            "check ATVL balance"
        );
    }

    function test_redeem_usdtDepeg_suffLiquidity() external {
        uint256 _amount = 1e6 * 1e18;

        //noDepeg at the time of depeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(981e5);

        //first making a deposit
        _depositNSTBL(_amount);
        vm.stopPrank();
        //deposited

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(981e5);

        //redeeming 10% of the liquidity
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        nstblHub.redeem(_amount / 10, user1);
        vm.stopPrank();
        uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
        //redeemed only 10% of the liquidity
        assertEq((_amount * 8 / 100) / 10 ** 12, usdcBalBefore - usdcBalAfter, "check USDC balance");
        assertEq(((_amount * 1 / 100) * 980 / 975) / 10 ** 12, usdtBalBefore - usdtBalAfter, "check USDT balance");
        assertEq((_amount * 1 / 100), daiBalBefore - daiBalAfter, "check DAI balance");
        assertEq(nstblBalBefore - nstblToken.balanceOf(nealthyAddr), _amount / 10, "check NSTBL balance");
    }

    function test_redeem_usdcDepeg_suffLiquidity() external {
        uint256 _amount = 1e6 * 1e18;

        //noDepeg at the time of depeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(981e5);

        //first making a deposit
        _depositNSTBL(_amount);

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(979e5);
        usdtPriceFeedMock.updateAnswer(983e5);
        daiPriceFeedMock.updateAnswer(981e5);

        //redeeming 10% of the liquidity
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        nstblHub.redeem(_amount / 10, user1);
        vm.stopPrank();
        uint256 usdcBalAfter = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalAfter = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalAfter = IERC20Helper(DAI).balanceOf(address(nstblHub));
        //redeemed only 10% of the liquidity
        assertEq(((_amount * 8 / 100) * 980 / 979) / 10 ** 12, usdcBalBefore - usdcBalAfter, "check USDC balance");
        assertEq((_amount * 1 / 100) / 10 ** 12, usdtBalBefore - usdtBalAfter, "check USDT balance");
        assertEq((_amount * 1 / 100), daiBalBefore - daiBalAfter, "check DAI balance");
        assertEq(nstblBalBefore - nstblToken.balanceOf(nealthyAddr), _amount / 10, "check NSTBL balance");
    }

    function test_redeem_daiUsdtDepeg_suffLiquidity_burnFromStakePool() external {
        uint256 _amount = 1e6 * 1e18;

        //noDepeg at the time of depeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(981e5);

        //first making a deposit
        _depositNSTBL(_amount);

        _stakeNSTBL(user1, _amount / 4, 0);
        deal(address(nstblToken), address(atvl), _amount * 12 / 1000); //1.2% of the total supply

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 stakePoolBalBefore = stakePool.poolBalance();
        vm.startPrank(nealthyAddr);
        // nstblToken.approve(address(nstblHub), _amount);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(988e5);
        usdtPriceFeedMock.updateAnswer(973e5);
        daiPriceFeedMock.updateAnswer(953e5); //dai below depeg

        //redeeming 10% of the liquidity
        nstblHub.redeem(10 * _amount / 100, user1);
        vm.stopPrank();

        //redeemed only 10% of the liquidity
        assertEq(
            (_amount * 8 / 100) / 10 ** 12,
            usdcBalBefore - IERC20Helper(USDC).balanceOf(address(nstblHub)),
            "check USDC balance"
        );
        assertEq(
            ((_amount * 1 / 100) * 980 / 973) / 10 ** 12,
            usdtBalBefore - IERC20Helper(USDT).balanceOf(address(nstblHub)),
            "check USDT balance"
        );
        assertEq(
            ((_amount * 1 / 100) * 980 / 953),
            daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub)),
            "check DAI balance"
        );
        assertApproxEqAbs(
            ((_amount * 1 / 100) * 980 / 973) + ((_amount * 1 / 100) * 980 / 970) - (_amount * 1 / 50),
            atvlBalBefore - nstblToken.balanceOf(address(atvl)),
            1e3,
            "check ATVL balance"
        );
        assertApproxEqAbs(
            ((_amount * 1 / 100) * 980 / 953) - ((_amount * 1 / 100) * 980 / 970),
            stakePoolBalBefore - stakePool.poolBalance(),
            1e3,
            "check StakePool balance"
        );
    }

    function test_redeem_daiUsdtUsdcDepeg_suffLiquidity_burnFromStakePool() external {
        uint256 _amount = 1e6 * 1e18;

        //noDepeg at the time of depeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(981e5);

        //first making a deposit
        _depositNSTBL(_amount);

        _stakeNSTBL(user1, _amount / 4, 0);
        deal(address(nstblToken), address(atvl), _amount * 12 / 1000); //1.2% of the total supply

        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
        vm.startPrank(nealthyAddr);
        // nstblToken.approve(address(nstblHub), _amount);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(958e5);
        usdtPriceFeedMock.updateAnswer(973e5);
        daiPriceFeedMock.updateAnswer(953e5); //dai below depeg

        //redeeming 10% of the liquidity
        nstblHub.redeem(10 * _amount / 100, user1);
        vm.stopPrank();

        //redeemed only 10% of the liquidity
        assertEq(
            ((_amount * 8 / 100) * 980 / 958) / 10 ** 12,
            usdcBalBefore - IERC20Helper(USDC).balanceOf(address(nstblHub)),
            "check USDC balance"
        );
        assertEq(
            ((_amount * 1 / 100) * 980 / 973) / 10 ** 12,
            usdtBalBefore - IERC20Helper(USDT).balanceOf(address(nstblHub)),
            "check USDT balance"
        );
        assertEq(
            ((_amount * 1 / 100) * 980 / 953),
            daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub)),
            "check DAI balance"
        );
    }
}
