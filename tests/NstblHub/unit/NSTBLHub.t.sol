pragma solidity 0.8.21;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Helper, BaseTest, ERC20, NSTBLHub, TransparentUpgradeableProxy } from "../helpers/BaseTest.t.sol";

// contract testProxy is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function test_proxy_hub() external {
//         assertEq(nstblHub.nstblToken(), address(nstblToken));
//         assertEq(nstblHub.stakePool(), address(stakePool));
//         assertEq(nstblHub.chainLinkPriceFeed(), address(priceFeed));
//         assertEq(nstblHub.atvl(), address(atvl));
//         assertEq(nstblHub.loanManager(), address(loanManager));
//         assertEq(nstblHub.aclManager(), address(aclManager));
//         assertEq(nstblHub.eqTh(), 2 * 1e22);
//         assertEq(nstblHub.getVersion(), 1);
//     }

//     function test_proxy_hub_setup() external {
//         vm.startPrank(owner);
//         NSTBLHub hubImp2 = new NSTBLHub();
//         bytes memory data1 = abi.encodeCall(
//             nstblHubImpl.initialize,
//             (
//                 address(nstblToken),
//                 address(stakePool),
//                 address(priceFeed),
//                 address(atvl),
//                 address(loanManager),
//                 address(aclManager),
//                 3 * 1e24
//             )
//         );
//         TransparentUpgradeableProxy proxyNew =
//             new TransparentUpgradeableProxy(address(hubImp2), address(proxyAdmin), data1);
//         vm.stopPrank();
//         NSTBLHub hub2 = NSTBLHub(address(proxyNew));
//         assertEq(hub2.nstblToken(), address(nstblToken));
//         assertEq(hub2.stakePool(), address(stakePool));
//         assertEq(hub2.eqTh(), 3 * 1e24);
//     }
// }

// contract testATVL is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function test_init() external {
//         vm.prank(deployer);
//         atvl.init(vm.addr(345), 1000);
//         assertEq(atvl.nstblToken(), vm.addr(345));
//         assertEq(atvl.atvlThreshold(), 1000);

//         vm.startPrank(deployer);
//         vm.expectRevert("ATVL: invalid Address");
//         atvl.init(address(0), 1000);
//         vm.expectRevert("ATVL: invalid Threshold");
//         atvl.init(vm.addr(1234), 0);
//         vm.stopPrank();
//     }

//     function test_setAuthorizedCaller() external {
//         vm.prank(deployer);
//         atvl.setAuthorizedCaller(vm.addr(345), true);
//         assertEq(atvl.authorizedCallers(vm.addr(345)), true);
//     }

//     function test_skimProfits() external {
//         //precondition
//         _depositNSTBL(1e6 * 1e18);

//         assertEq(nstblToken.totalSupply(), 1e6 * 1e18);
//         assertEq(nstblToken.balanceOf(nealthyAddr), 1e6 * 1e18);

//         vm.prank(nealthyAddr);
//         nstblToken.transfer(address(atvl), 2e4 * 1e18); //transferring 2% of the circulating supply to atvl

//         assertEq(nstblToken.balanceOf(address(atvl)), 2e4 * 1e18);

//         uint256 balBefore = nstblToken.balanceOf(vm.addr(123_456_789));

//         //action
//         vm.startPrank(deployer);
//         uint256 nstblAmt = atvl.skimProfits(vm.addr(123_456_789));
//         vm.stopPrank();

//         //postcondition
//         assertEq(nstblAmt, 8000 * 1e18, "check skim amount");
//         assertEq(nstblToken.balanceOf(vm.addr(123_456_789)) - balBefore, 8000 * 1e18, "check transferred amount");
//         assertEq(nstblToken.balanceOf(address(atvl)), 12_000 * 1e18, "check remaining balance");
//     }
// }

// contract testSetters is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function test_setSytemParams() external {
//         vm.startPrank(deployer);

//         vm.expectRevert("HUB: Invalid T-Bill Percent");
//         nstblHub.setSystemParams(99e6, 98e6, 97e6, 6e3, 3 * 1e22);
//         vm.expectRevert("HUB: Invalid Equilibrium Threshold");
//         nstblHub.setSystemParams(99e6, 98e6, 97e6, 8e3, 9 * 1e22);

//         nstblHub.setSystemParams(99e6, 98e6, 97e6, 8e3, 3 * 1e22);
//         vm.stopPrank();
//         assertEq(nstblHub.dt(), 99e6);
//         assertEq(nstblHub.ub(), 98e6);
//         assertEq(nstblHub.lb(), 97e6);
//         assertEq(nstblHub.tBillPercent(), 8e3);
//     }

//     function test_updateAssetFeeds() external {
//         vm.prank(deployer);
//         nstblHub.updateAssetFeeds([address(usdtPriceFeedMock), address(usdcPriceFeedMock), address(daiPriceFeedMock)]);
//         assertEq(nstblHub.assetFeeds(0), address(usdtPriceFeedMock));
//         assertEq(nstblHub.assetFeeds(1), address(usdcPriceFeedMock));
//         assertEq(nstblHub.assetFeeds(2), address(daiPriceFeedMock));
//     }
// }

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

        //usdt also depegs
        usdtPriceFeedMock.updateAnswer(971e5);
        deal(USDC, nealthyAddr, 1e6 * 1e6);
        deal(USDT, nealthyAddr, 1e6 * 1e6);
        deal(DAI, nealthyAddr, 1e6 * 1e18);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e6);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), 1e6 * 1e18);
        vm.expectRevert("HUB: Invalid Deposit");
        nstblHub.deposit(0, 0, 0);
        vm.stopPrank();
    }

    function test_deposit_revert_invalid_eq() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        vm.expectRevert("HUB::Deposit Not Allowed");
        nstblHub.deposit(usdcAmt * 110 / 100, usdtAmt * 105 / 100, daiAmt * 95 / 100); //over 2% deviation in deposit amounts

        vm.stopPrank();

        _depositNSTBL(1e6 * 1e18);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        vm.expectRevert("HUB::Deposit Not Allowed");
        nstblHub.deposit(usdcAmt * 110 / 100, usdtAmt * 105 / 100, daiAmt * 95 / 100);

        _depositNSTBL(1e6 * 1e18);

        assertEq(nstblToken.totalSupply(), 2e6 * 1e18);
    }

    function test_deposit_fail_invalid_investment() external {
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(985e5);
        daiPriceFeedMock.updateAnswer(985e5);
        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;

        vm.expectRevert("HUB: Invalid Investment Amount");
        (usdcAmt, usdtAmt, daiAmt,) = nstblHub.previewDeposit(1e10);
        (usdcAmt, usdtAmt, daiAmt) = (8e9 * 1e6, 1e9 * 1e6, 1e9 * 1e18);
        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

        vm.expectRevert("HUB: Invalid Investment");
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopPrank();
    }

    function test_deposit_noDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

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

        assertEq(nstblHub.stablesBalances(USDC), usdcAmt - tBillAmt);
        assertEq(nstblHub.stablesBalances(USDT), usdtAmt);
        assertEq(nstblHub.stablesBalances(DAI), daiAmt);
        assertEq(nstblHub.usdcInvested(), tBillAmt);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
        vm.warp(block.timestamp + 1000000 days);

        // _depositNSTBL(1e6 * 1e18);

        // assertApproxEqAbs(
        //     loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 1e13, "check invested amount in maple"
        // );

        uint256[] memory balances = new uint256[](3);
        balances[0] = loanManager.getMaturedAssets() + nstblHub.stablesBalances(USDC) * 1e12;
        balances[1] = nstblHub.stablesBalances(USDT) * 1e12;
        balances[2] = nstblHub.stablesBalances(DAI);
        uint256 tvl = balances[0] + balances[1] + balances[2];
        uint256 maxRedeem = hubViews.getMaxRedeemAmount();
        console.log("Max Redeem Amount: ", maxRedeem, tvl);
        console.log("usdc Balance: ", nstblHub.stablesBalances(USDC)*1e12, balances[0]*maxRedeem/tvl);
        console.log("usdt Balance and requirement: ", nstblHub.stablesBalances(USDT)*1e12, nstblHub.stablesBalances(USDT)*1e12*maxRedeem/ tvl);
        console.log("dai Balance and requirement: ", nstblHub.stablesBalances(DAI), nstblHub.stablesBalances(DAI)*maxRedeem/ tvl);

        console.log("NSTBL Price: ", hubViews.getNSTBLPrice());
    }

    // function test_deposit_case2() external {
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(983e5);
    //     daiPriceFeedMock.updateAnswer(985e5);

    //     assertTrue(nstblHub.validateDepositEquilibrium(797e3 * 1e6, 101e3 * 1e6, 102e3 * 1e18));
    //     uint256 usdcAmt = 798e3 * 1e6;
    //     uint256 usdtAmt = 100e3 * 1e6;
    //     uint256 daiAmt = 102e3 * 1e18;
    //     deal(USDC, nealthyAddr, usdcAmt);
    //     deal(USDT, nealthyAddr, usdtAmt);
    //     deal(DAI, nealthyAddr, daiAmt);

    //     vm.startPrank(nealthyAddr);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

    //     // vm.expectRevert("HUB::Deposit Not Allowed!");
    //     nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
    //     vm.stopPrank();

    //     assertFalse(nstblHub.validateDepositEquilibrium(900e3 * 1e6, 101e3 * 1e6, 102e3 * 1e18));
    //     assertTrue(nstblHub.validateDepositEquilibrium(806e3 * 1e6, 101e3 * 1e6, 102e3 * 1e18));
    // }

    function test_deposit_usdcDepeg() external {
        //nodepeg
        usdcPriceFeedMock.updateAnswer(980e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

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
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(979e5);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(nstblHub.stablesBalances(USDC), usdcAmt - tBillAmt);
        assertEq(nstblHub.stablesBalances(USDT), usdtAmt);
        assertEq(nstblHub.stablesBalances(DAI), daiAmt);
        assertEq(nstblHub.usdcInvested(), tBillAmt);
        assertEq(IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM, tBillAmt);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
        assertApproxEqAbs(
            loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 1e13, "check invested amount in maple"
        );
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

        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        vm.stopPrank();

        assertEq(nstblHub.stablesBalances(USDC), usdcAmt - tBillAmt);
        assertEq(nstblHub.stablesBalances(USDT), usdtAmt);
        assertEq(nstblHub.stablesBalances(DAI), daiAmt);
        assertEq(nstblHub.usdcInvested(), tBillAmt);
        assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);
        assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    }

    // function test_deposit_consecutive_deposit() external {
    //     //no depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(981e5);
    //     daiPriceFeedMock.updateAnswer(985e5);

    //     _depositNSTBL(1e6 * 1e18);

    //     assertEq(nstblHub.stablesBalances(USDC), 1e5 * 1e6);
    //     assertEq(nstblHub.stablesBalances(USDT), 1e5 * 1e6);
    //     assertEq(nstblHub.stablesBalances(DAI), 1e5 * 1e18);
    //     assertApproxEqAbs(loanManager.getMaturedAssets(), 7e5 * 1e18, 1e13);
    //     assertApproxEqAbs(
    //         loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 1e13, "check invested amount in maple"
    //     );

    //     vm.warp(block.timestamp + 100 days);

    //     uint256 usdcAmt = 784e3 * 1e6;
    //     uint256 usdtAmt = 102e3 * 1e6;
    //     uint256 daiAmt = 100e3 * 1e18;
    //     deal(USDC, nealthyAddr, usdcAmt);
    //     deal(USDT, nealthyAddr, usdtAmt);
    //     deal(DAI, nealthyAddr, daiAmt);

    //     vm.startPrank(nealthyAddr);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

    //     nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
    //     vm.stopPrank();

    //     assertApproxEqRel(
    //         loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 5e15, "check invested amount in maple"
    //     );
    // }

    // function test_deposit_consecutive_deposit_no_maple_investment() external {
    //     //no depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(981e5);
    //     daiPriceFeedMock.updateAnswer(985e5);

    //     _depositNSTBL(1e6 * 1e18);

    //     assertEq(nstblHub.stablesBalances(USDC), 1e5 * 1e6);
    //     assertEq(nstblHub.stablesBalances(USDT), 1e5 * 1e6);
    //     assertEq(nstblHub.stablesBalances(DAI), 1e5 * 1e18);
    //     assertApproxEqAbs(loanManager.getMaturedAssets(), 7e5 * 1e18, 1e13);
    //     assertApproxEqAbs(
    //         loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 1e13, "check invested amount in maple"
    //     );

    //     vm.warp(block.timestamp + 100 days);

    //     _depositNSTBL(1e3 * 1e18);

    //     assertApproxEqRel(
    //         loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 5e15, "check invested amount in maple"
    //     );
    // }

    // function test_deposit_consecutive_deposit_fuzz(uint256 _amount1, uint256 _amount2) external {
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(981e5);
    //     daiPriceFeedMock.updateAnswer(985e5);
    //     _amount1 = bound(_amount1, 100e18, _getUpperBoundDeposit() * 1e12 / 4);
    //     _amount2 = bound(_amount2, 100e18, _getUpperBoundDeposit() * 1e12 / 2);

    //     _depositNSTBL(_amount1);

    //     assertApproxEqRel(
    //         loanManager.getMaturedAssets(),
    //         7e3 * nstblToken.totalSupply() / 1e4,
    //         5e15,
    //         "check invested amount in maple1"
    //     );

    //     vm.warp(block.timestamp + 100 days);

    //     //usdt depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(985e5);
    //     daiPriceFeedMock.updateAnswer(985e5);

    //     //randomizing 1% deviation here
    //     (uint256 usdcAmt, uint256 usdtAmt, uint256 daiAmt) = _randomizeDepositAmounts(_amount2);
    //     deal(USDC, nealthyAddr, usdcAmt);
    //     deal(USDT, nealthyAddr, usdtAmt);
    //     deal(DAI, nealthyAddr, daiAmt);

    //     vm.startPrank(nealthyAddr);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

    //     nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
    //     vm.stopPrank();
    //     assertApproxEqRel(
    //         loanManager.getMaturedAssets(),
    //         7e3 * nstblToken.totalSupply() / 1e4,
    //         5e15,
    //         "check invested amount in maple2"
    //     );
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

    //     if (_price1 <= int256(nstblHub.dt())) {
    //         vm.expectRevert("HUB: Invalid Deposit");
    //     }
    //     (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(1e6);

    //     deal(USDC, nealthyAddr, usdcAmt);
    //     deal(USDT, nealthyAddr, usdtAmt);
    //     deal(DAI, nealthyAddr, daiAmt);

    //     uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

    //     if (usdcAmt + usdtAmt + daiAmt == 0) {
    //         vm.expectRevert("HUB: Invalid Deposit");
    //     }
    //     nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

    //     vm.stopPrank();

    //     assertEq(nstblHub.stablesBalances(USDC), usdcAmt - tBillAmt);
    //     assertEq(nstblHub.stablesBalances(USDT), usdtAmt);
    //     assertEq(nstblHub.stablesBalances(DAI), daiAmt);
    //     assertEq(nstblHub.usdcInvested(), tBillAmt);
    //     assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
    //     assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

    //     assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    // }

    // function test_fixed_deposit_fuzz_pricesAndDepositAmount(
    //     int256 _price1,
    //     int256 _price2,
    //     int256 _price3,
    //     uint256 _amount
    // ) external {
    //     _price1 = bound(_price1, 97e6, 1e8);
    //     _price2 = bound(_price2, 97e6, 1e8);
    //     _price3 = bound(_price3, 97e6, 1e8);
    //     _amount = bound(_amount, 100, _getUpperBoundDeposit() / 1e6);

    //     usdcPriceFeedMock.updateAnswer(_price1);
    //     usdtPriceFeedMock.updateAnswer(_price2);
    //     daiPriceFeedMock.updateAnswer(_price2);

    //     uint256 usdcAmt;
    //     uint256 usdtAmt;
    //     uint256 daiAmt;
    //     uint256 tBillAmt;

    //     if (_price1 <= int256(nstblHub.dt())) {
    //         vm.expectRevert("HUB: Invalid Deposit");
    //     }
    //     (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(_amount);

    //     deal(USDC, nealthyAddr, usdcAmt);
    //     deal(USDT, nealthyAddr, usdtAmt);
    //     deal(DAI, nealthyAddr, daiAmt);

    //     uint256 usdcBalBeforeLM = IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL);
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     vm.startPrank(nealthyAddr);
    //     IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
    //     IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
    //     IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);

    //     if (usdcAmt + usdtAmt + daiAmt == 0) {
    //         vm.expectRevert("HUB: Invalid Deposit");
    //     }
    //     nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);

    //     uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);

    //     vm.stopPrank();

    //     assertEq(nstblHub.stablesBalances(USDC), usdcAmt - tBillAmt);
    //     assertEq(nstblHub.stablesBalances(USDT), usdtAmt);
    //     assertEq(nstblHub.stablesBalances(DAI), daiAmt);
    //     assertEq(nstblHub.usdcInvested(), tBillAmt);
    //     assertEq(tBillAmt, IERC20Helper(USDC).balanceOf(MAPLE_USDC_CASH_POOL) - usdcBalBeforeLM);
    //     assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblBalAfter - nstblBalBefore);

    //     assertEq((usdcAmt + usdtAmt) * 1e12 + daiAmt, nstblToken.balanceOf(nealthyAddr));
    //     assertApproxEqRel(
    //         loanManager.getMaturedAssets(),
    //         7e3 * nstblToken.totalSupply() / 1e4,
    //         5e15,
    //         "check invested amount in maple2"
    //     );
    // }
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
        nstblHub.stake(user1, 5e6 * 1e18, 0);

        vm.expectRevert("HUB: INVALID_ADDRESS");
        nstblHub.stake(address(0), 2e6 * 1e18, 0);

        vm.stopPrank();
    }

    function test_stake() external {
        //preConditions

        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(2e6 * 1e18, nstblToken.balanceOf(address(stakePool)));
        assertEq(8e6 * 1e18, nstblToken.balanceOf(nealthyAddr));

        (uint256 amount, uint256 poolDebt,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, 1e6 * 1e18);
        assertEq(poolDebt, 1e18);
        assertEq(stakePool.poolBalance(), 2e6 * 1e18);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        (amount, poolDebt,,) = stakePool.getStakerInfo(user1, 0);

        assertEq(
            stakePool.poolBalance() + nstblToken.balanceOf(address(atvl)),
            3e6 * 1e18 + (loanManager.getMaturedAssets() - maturityVal)
        );
    }

    function test_stake_case2() external {
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e3 * 1e18);
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(nstblToken.totalSupply(), 10e3 * 1e18, "check total supply");

        //time warp for 40 hours
        vm.warp(block.timestamp + 40 hours);

        // usdtdepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(975e5);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _stakeNSTBL(user1, 1e3 * 1e18, 0);

        //postConditions
        assertEq(1e3 * 1e18, nstblToken.balanceOf(address(stakePool)), "check stake pool Balance");
        assertEq(9e3 * 1e18, nstblToken.balanceOf(nealthyAddr), "check nealthy address balance");
        assertEq(
            nstblToken.totalSupply(), 10e3 * 1e18 + loanManager.getMaturedAssets() - maturityVal, "check total supply"
        );

        (uint256 amount,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, 1e3 * 1e18);
        assertEq(stakePool.poolBalance(), 1e3 * 1e18);
    }

    function test_stake_tokenomia_problem() external {
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);
        _depositNSTBL(97e5*1e18);
        assertEq(nstblToken.totalSupply(), 97e5*1e18);
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        
        vm.warp(block.timestamp + 365 days);
        console.log("NSTBL SUPPLY before : ", nstblToken.totalSupply());
        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        console.log("NSTBL SUPPLY after : ", nstblToken.totalSupply());




    }

    function test_stake_fuzz(uint256 _amount) external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        uint256 tBillInvestUB = loanManager.getDepositUpperBound();
        _amount = bound(_amount, 1, tBillInvestUB * 100 / (1e6 * 70));
        _amount *= 1e18;

        //actions
        _depositNSTBL(_amount);

        uint256 maxStakeAmount = 40 * nstblToken.totalSupply() / 100;
        // maxStakeAmount = 30*maxStakeAmount/100;
        _stakeNSTBL(user1, maxStakeAmount / 2, 0); //user1 users maxStakeAmount/2
        _stakeNSTBL(user2, maxStakeAmount / 4, 1); //user2 users maxStakeAmount/4

        //postConditions
        uint256 maturityVal = stakePool.oldMaturityVal();
        assertEq(3 * maxStakeAmount / 4, stakePool.poolBalance(), "check pool Balance");

        (uint256 amount, uint256 poolDebt,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount, maxStakeAmount / 2);
        assertEq(poolDebt, 1e18);

        vm.warp(block.timestamp + 30 days);

        //restaking
        _stakeNSTBL(user1, maxStakeAmount / 4, 0);
        (amount, poolDebt,,) = stakePool.getStakerInfo(user1, 0);

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

        //actions
        _depositNSTBL(10e6 * 1e18);

        _stakeNSTBL(user1, 1e6 * 1e18, 0);
        _stakeNSTBL(user2, 1e6 * 1e18, 1);

        //postConditions
        (uint256 amount,,,) = stakePool.getStakerInfo(user1, 0);

        vm.warp(block.timestamp + 30 days);
        //restaking
        _stakeNSTBL(user1, 1e6 * 1e18, 0);

        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
        uint256 balBefore = nstblToken.balanceOf(destinationAddress);
        (amount,,,) = stakePool.getStakerInfo(user1, 0);

        //action
        _unstakeNSTBL(user1, 0);
        (uint256 amount2,,,) = stakePool.getStakerInfo(user1, 0);
        uint256 balAfter = nstblToken.balanceOf(destinationAddress);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

        //postConditions
        assertEq(amount2, 0);
        assertEq(balAfter - balBefore + (atvlBalAfter - atvlBalBefore), amount);
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

        uint256 balBefore = nstblToken.balanceOf(destinationAddress);

        //action
        _unstakeNSTBL(user1, 0);
        _unstakeNSTBL(user2, 1);

        //postConditions
        (uint256 amount2,,,) = stakePool.getStakerInfo(user1, 0);
        uint256 balAfter = nstblToken.balanceOf(destinationAddress);
        uint256 atvlBalAfter = nstblToken.balanceOf(address(atvl));

        assertEq(amount2, 0);
        if ((loanManager.getMaturedAssets() - oldMaturityVal) > 1e18) {
            assertApproxEqAbs(
                balAfter - balBefore + (atvlBalAfter - atvlBalBefore),
                maxStakeAmount + (loanManager.getMaturedAssets() - oldMaturityVal),
                1e12,
                "with yield"
            );
        } else {
            assertEq(balAfter - balBefore + (atvlBalAfter - atvlBalBefore), maxStakeAmount, "without yield");
        }
    }

    function test_unstake_Depeg() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        uint256 daiBalance = nstblHub.stablesBalances(DAI);
        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 2e6 * 1e18, 0);

        //postConditions
        (uint256 amount,,,) = stakePool.getStakerInfo(user1, 0);

        assertEq(amount, 2e6 * 1e18);

        vm.warp(block.timestamp + 30 days);

        uint256 unstakeAmount = stakePool.getUserAvailableTokens(user1, 0);

        //one asset depegs just before unstaking
        daiPriceFeedMock.updateAnswer(975e5);

        uint256 balBefore = nstblToken.balanceOf(destinationAddress);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(destinationAddress);

        (uint256 a1, address[] memory stables, uint256[] memory stablesAmount) = hubViews.previewUnstake(user1, 0);
        console.log("Unstake Preview: ");
        console.log(a1, stables[0], stablesAmount[0]);
        //action
        _unstakeNSTBL(user1, 0);
        assertEq(nstblHub.stablesBalances(DAI), 0); //all the failing stable is drained
        assertEq(
            nstblToken.balanceOf(destinationAddress) - balBefore,
            unstakeAmount - (daiBalance * 975e5 / 98e6),
            "check nstbl transferred"
        );
        console.log(
            nstblToken.balanceOf(destinationAddress) - balBefore,
            unstakeAmount - (daiBalance * 975e5 / 98e6),
            "check nstbl transferred"
        );

        assertEq(IERC20Helper(DAI).balanceOf(destinationAddress) - daiBalBefore, daiBalance, "check dai transferred");
        console.log(IERC20Helper(DAI).balanceOf(destinationAddress) - daiBalBefore, daiBalance, "check dai transferred");
        (uint256 amount2,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount2, 0);
    }

    function test_unstake_AllDepeg() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        uint256 usdcBalance = nstblHub.stablesBalances(USDC) * 1e12;
        uint256 usdtBalance = nstblHub.stablesBalances(USDT) * 1e12;
        uint256 daiBalance = nstblHub.stablesBalances(DAI);

        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 39e5 * 1e18, 0);

        vm.warp(block.timestamp + 30 days);

        uint256 unstakeAmount = stakePool.getUserAvailableTokens(user1, 0);

        //all assets depeg just before unstaking
        usdcPriceFeedMock.updateAnswer(979e5);
        usdtPriceFeedMock.updateAnswer(976e5);
        daiPriceFeedMock.updateAnswer(973e5);

        uint256 balBefore = nstblToken.balanceOf(destinationAddress);
        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(destinationAddress);
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(destinationAddress);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(destinationAddress);

        (uint256 a1, address[] memory stables, uint256[] memory stablesAmount) = hubViews.previewUnstake(user1, 0);
        console.log("Unstake Preview: ");
        console.log(a1, stables[0], stablesAmount[0]);
        console.log(a1, stables[1], stablesAmount[1]);
        console.log(a1, stables[2], stablesAmount[2]);
        //action
        _unstakeNSTBL(user1, 0);
        assertEq(nstblHub.stablesBalances(USDC), 0);
        assertEq(nstblHub.stablesBalances(USDT), 0);
        assertEq(nstblHub.stablesBalances(DAI), 0);
        assertEq(
            nstblToken.balanceOf(destinationAddress) - balBefore,
            unstakeAmount - (usdcBalance * 979e5 / 98e6) - (usdtBalance * 976e5 / 98e6) - (daiBalance * 973e5 / 98e6),
            "check nstbl transferred"
        );
        assertEq(
            IERC20Helper(USDC).balanceOf(destinationAddress) - usdcBalBefore,
            usdcBalance / 1e12,
            "check usdc transferred"
        );
        assertEq(
            IERC20Helper(USDT).balanceOf(destinationAddress) - usdtBalBefore,
            usdtBalance / 1e12,
            "check usdt transferred"
        );
        assertEq(IERC20Helper(DAI).balanceOf(destinationAddress) - daiBalBefore, daiBalance, "check dai transferred");
    }

    function test_unstake_Depeg_belowUB() external {
        //preConditions
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        //actions
        _depositNSTBL(10e6 * 1e18);
        uint256 daiBalance = nstblHub.stablesBalances(DAI);
        deal(address(nstblToken), address(atvl), 36e3 * 1e18); //1% of the Total supply

        _stakeNSTBL(user1, 2e6 * 1e18, 0);

        //postConditions
        (uint256 amount,,,) = stakePool.getStakerInfo(user1, 0);

        assertEq(amount, 2e6 * 1e18);

        vm.warp(block.timestamp + 30 days);

        uint256 unstakeAmount = stakePool.getUserAvailableTokens(user1, 0);

        //one asset depegs below ub just before unstaking
        daiPriceFeedMock.updateAnswer(965e5);

        uint256 balBefore = nstblToken.balanceOf(destinationAddress);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(destinationAddress);

        //action
        _unstakeNSTBL(user1, 0);
        assertEq(nstblHub.stablesBalances(DAI), 0); //all the failing stable is drained
        assertEq(
            nstblToken.balanceOf(destinationAddress) - balBefore,
            unstakeAmount - (daiBalance * 965e5 / 1005e5),
            "check nstbl transferred"
        );
        assertEq(IERC20Helper(DAI).balanceOf(destinationAddress) - daiBalBefore, daiBalance, "check dai transferred");
        (uint256 amount2,,,) = stakePool.getStakerInfo(user1, 0);
        assertEq(amount2, 0);
    }

    function test_unstake_audit_case1() external {
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        _depositNSTBL(5e6 * 1e18); //for user1
        _depositNSTBL(5e6 * 1e18); //for user2
        deal(address(nstblToken), address(atvl), 36e3 * 1e18);

        _stakeNSTBL(user1, 1e5 * 1e18, 0);
        _stakeNSTBL(user2, 1e5 * 1e18, 0);

        vm.warp(block.timestamp + 30 days);

        daiPriceFeedMock.updateAnswer(971e5); //dai depeg

        vm.prank(nealthyAddr);
        nstblHub.redeem(25 * 5e6 * 1e18 / 1000, user2);

        _unstakeNSTBL(user1, 0);
    }

    function test_unstake_audit_case2() external {
        // nodepeg
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(985e5);

        _depositNSTBL(5e6 * 1e18); //for user1
        _depositNSTBL(5e6 * 1e18); //for user2
        deal(address(nstblToken), address(atvl), 36e3 * 1e18);

        _stakeNSTBL(user1, 1e5 * 1e18, 0);

        vm.warp(block.timestamp + 30 days);

        daiPriceFeedMock.updateAnswer(971e5); //dai depeg

        vm.prank(nealthyAddr);
        nstblHub.redeem(25 * 5e6 * 1e18 / 1000, user2);

        _unstakeNSTBL(user1, 0);
    }
}

contract NSTBLHubTestRedeem is BaseTest {
    using SafeERC20 for IERC20Helper;

    function setUp() public override {
        super.setUp();
    }

    // function test_processTbillWithdraw_AwaitingRedemption() external {
    //     vm.startPrank(nealthyAddr);
    //     vm.store(address(loanManager), bytes32(uint256(5)), bytes32(uint256(type(uint256).max)));
    //     assertEq(loanManager.awaitingRedemption(), true);
    //     vm.expectRevert();
    //     nstblHub.processTBillWithdraw();
    //     vm.stopPrank();
    // }

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

        uint256 usdcTotal = nstblHub.stablesBalances(USDC) * 1e12 + loanManager.getMaturedAssets();

        uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
        uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
        uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
        uint256 tvl = usdcTotal + usdtBalBefore * 1e12 + daiBalBefore;
        uint256 usdcAlloc = usdcTotal * 1e18 / tvl;
        uint256 usdtAlloc = usdtBalBefore * 1e12 * 1e18 / tvl;
        uint256 daiAlloc = daiBalBefore * 1e18 / tvl;
        uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);
        //can redeem only 12.5% of the liquidity
        nstblHub.redeem(125e3 * 1e18, user1);
        vm.stopPrank();

        uint256 nstblBalAfter = nstblToken.balanceOf(nealthyAddr);
        //redeemed only 12.5% of the liquidity

        assertEq(
            ((125e3 * 1e6) * usdcAlloc) / (1e18),
            usdcBalBefore - nstblHub.stablesBalances(USDC),
            "check usdc transferred"
        );
        assertEq(
            ((125e3 * 1e6) * usdtAlloc) / (1e18),
            usdtBalBefore - nstblHub.stablesBalances(USDT),
            "check usdt transferred"
        );
        assertEq(
            ((125e3 * 1e18) * daiAlloc) / (1e18), daiBalBefore - nstblHub.stablesBalances(DAI), "check dai transferred"
        );

        assertEq(125e3 * 1e18, nstblBalBefore - nstblBalAfter); //burned tokens from the user

        //checking for T-bill redemption status
        assertTrue(loanManager.awaitingRedemption());

        usdcBalBefore = nstblHub.stablesBalances(USDC);
        vm.startPrank(nealthyAddr);
        vm.expectRevert("LM: Not in Window");
        uint256 stablesRedeemed = nstblHub.processTBillWithdraw();

        (uint256 windowStart,) = loanManager.getRedemptionWindow();
        vm.warp(windowStart);
        stablesRedeemed = nstblHub.processTBillWithdraw();

        assertEq(stablesRedeemed, nstblHub.stablesBalances(USDC) - usdcBalBefore, "check stables redeemed");
        console.log(stablesRedeemed, nstblHub.stablesBalances(USDC) - usdcBalBefore, "check stables redeemed");

        // assertApproxEqRel(
        //     loanManager.getMaturedAssets(), 7e3 * nstblToken.totalSupply() / 1e4, 5e15, "check invested amount in maple"
        // );
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

        uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
        uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
        uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
        uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));

        vm.startPrank(nealthyAddr);

        //depeg at the time of redemption
        usdcPriceFeedMock.updateAnswer(982e5);
        usdtPriceFeedMock.updateAnswer(99e6);
        daiPriceFeedMock.updateAnswer(975e5);

        console.log("NSTBL Price: ", hubViews.getNSTBLPrice());

        //redeeming 10% of the liquidity

        nstblHub.redeem(10 * _amount / 100, user1);
        vm.stopPrank();
        //redeemed only 10% of the liquidity
        assertApproxEqAbs(
            (_amount * 8 / 100) / 10 ** 12, usdcBalBefore - nstblHub.stablesBalances(USDC), 1, "check USDC balance"
        );
        assertApproxEqAbs(
            (_amount * 1 / 100) / 10 ** 12, usdtBalBefore - nstblHub.stablesBalances(USDT), 1, "check USDT balance"
        );
        assertApproxEqAbs(
            (_amount * 1 / 100) * 980e5 / 975e5, daiBalBefore - nstblHub.stablesBalances(DAI), 1e12, "check DAI balance"
        );
        assertApproxEqAbs(
            atvlBalBefore - nstblToken.balanceOf(address(atvl)),
            ((_amount * 1 / 100) * 980e5 / 975e5) - (_amount * 1 / 100),
            1e12,
            "check ATVL balance"
        );
    }

    // function test_redeem_usdtDepeg_suffLiquidity() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);
    //     vm.stopPrank();
    //     //deposited

    //     uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);

    //     //depeg at the time of redemption
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(975e5);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //redeeming 10% of the liquidity
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     nstblHub.redeem(_amount / 10, user1);
    //     vm.stopPrank();
    //     uint256 usdcBalAfter = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalAfter = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalAfter = nstblHub.stablesBalances(DAI);
    //     //redeemed only 10% of the liquidity
    //     assertApproxEqAbs((_amount * 8 / 100) / 10 ** 12, usdcBalBefore - usdcBalAfter, 1, "check USDC balance");
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 975) / 10 ** 12, usdtBalBefore - usdtBalAfter, 1, "check USDT balance"
    //     );
    //     assertApproxEqAbs((_amount * 1 / 100), daiBalBefore - daiBalAfter, 1e13, "check DAI balance");
    //     assertEq(nstblBalBefore - nstblToken.balanceOf(nealthyAddr), _amount / 10, "check NSTBL balance");
    // }

    // function test_redeem_usdcDepeg_suffLiquidity() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);

    //     uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
    //     vm.startPrank(nealthyAddr);
    //     nstblToken.approve(address(nstblHub), _amount);

    //     //depeg at the time of redemption
    //     usdcPriceFeedMock.updateAnswer(979e5);
    //     usdtPriceFeedMock.updateAnswer(983e5);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //redeeming 10% of the liquidity
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     nstblHub.redeem(_amount / 10, user1);
    //     vm.stopPrank();

    //     //redeemed only 10% of the liquidity
    //     assertApproxEqAbs(
    //         ((_amount * 8 / 100) * 980 / 979) / 10 ** 12,
    //         usdcBalBefore - nstblHub.stablesBalances(USDC),
    //         1,
    //         "check USDC balance"
    //     );
    //     assertApproxEqAbs(
    //         (_amount * 1 / 100) / 10 ** 12, usdtBalBefore - nstblHub.stablesBalances(USDT), 1, "check USDT balance"
    //     );
    //     assertApproxEqAbs((_amount * 1 / 100), daiBalBefore - nstblHub.stablesBalances(DAI), 1e12, "check DAI balance");
    //     assertEq(nstblBalBefore - nstblToken.balanceOf(nealthyAddr), _amount / 10, "check NSTBL balance");
    // }

    // function test_redeem_usdtDepeg_burnFromStakePool() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);

    //     _stakeNSTBL(user1, _amount / 10, 0);
    //     deal(address(nstblToken), address(atvl), _amount * 12 / 1000); //1.2% of the total supply

    //     uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
    //     uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
    //     uint256 stakePoolBalBefore = stakePool.poolBalance();
    //     vm.startPrank(nealthyAddr);
    //     // nstblToken.approve(address(nstblHub), _amount);

    //     //usdt depeg at the time of redemption
    //     usdtPriceFeedMock.updateAnswer(953e5);

    //     //redeeming 10% of the liquidity
    //     nstblHub.redeem(_amount / 10, user1);
    //     vm.stopPrank();

    //     //redeemed only 10% of the liquidity
    //     assertApproxEqAbs(
    //         (_amount * 8 / 100) / 10 ** 12, usdcBalBefore - nstblHub.stablesBalances(USDC), 1, "check USDC balance"
    //     );
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 953) / 10 ** 12,
    //         usdtBalBefore - nstblHub.stablesBalances(USDT),
    //         1,
    //         "check USDT balance"
    //     );
    //     assertApproxEqAbs((_amount * 1 / 100), daiBalBefore - nstblHub.stablesBalances(DAI), 1e12, "check DAI balance");
    //     assertApproxEqRel(
    //         ((_amount * 1 / 100) * 980 / 960) - (_amount * 1 / 100),
    //         atvlBalBefore - nstblToken.balanceOf(address(atvl)),
    //         1e10,
    //         "check ATVL balance"
    //     );
    //     assertApproxEqRel(
    //         ((_amount * 1 / 100) * 980 / 953) - ((_amount * 1 / 100) * 980 / 960),
    //         stakePoolBalBefore - stakePool.poolBalance(),
    //         1e10,
    //         "check StakePool balance"
    //     );
    // }

    // function test_redeem_daiUsdtDepeg_suffLiquidity_burnFromStakePool() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);

    //     _stakeNSTBL(user1, _amount / 4, 0);
    //     deal(address(nstblToken), address(atvl), _amount * 12 / 1000); //1.2% of the total supply

    //     uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
    //     uint256 atvlBalBefore = nstblToken.balanceOf(address(atvl));
    //     uint256 stakePoolBalBefore = stakePool.poolBalance();
    //     vm.startPrank(nealthyAddr);
    //     // nstblToken.approve(address(nstblHub), _amount);

    //     //depeg at the time of redemption
    //     usdcPriceFeedMock.updateAnswer(988e5);
    //     usdtPriceFeedMock.updateAnswer(973e5);
    //     daiPriceFeedMock.updateAnswer(953e5); //dai below depeg

    //     //redeeming 10% of the liquidity
    //     nstblHub.redeem(10 * _amount / 100, user1);
    //     vm.stopPrank();

    //     //redeemed only 10% of the liquidity
    //     assertApproxEqAbs(
    //         (_amount * 8 / 100) / 10 ** 12, usdcBalBefore - nstblHub.stablesBalances(USDC), 1, "check USDC balance"
    //     );
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 973) / 10 ** 12,
    //         usdtBalBefore - nstblHub.stablesBalances(USDT),
    //         1,
    //         "check USDT balance"
    //     );
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 953), daiBalBefore - nstblHub.stablesBalances(DAI), 1e12, "check DAI balance"
    //     );
    //     assertApproxEqRel(
    //         ((_amount * 1 / 100) * 980 / 973) + ((_amount * 1 / 100) * 980 / 960) - (_amount * 1 / 50),
    //         atvlBalBefore - nstblToken.balanceOf(address(atvl)),
    //         1e10,
    //         "check ATVL balance"
    //     );
    //     assertApproxEqRel(
    //         ((_amount * 1 / 100) * 980 / 953) - ((_amount * 1 / 100) * 980 / 960),
    //         stakePoolBalBefore - stakePool.poolBalance(),
    //         1e10,
    //         "check StakePool balance"
    //     );
    // }

    // function test_redeem_daiUsdtUsdcDepeg_suffLiquidity_burnFromStakePool() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);

    //     _stakeNSTBL(user1, _amount / 4, 0);
    //     deal(address(nstblToken), address(atvl), _amount * 50 / 1000); //5% of the total supply

    //     uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(address(nstblHub));
    //     uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(address(nstblHub));
    //     uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(address(nstblHub));
    //     uint256 nealthyBal = nstblToken.balanceOf(nealthyAddr);

    //     vm.startPrank(nealthyAddr);

    //     //depeg at the time of redemption
    //     usdcPriceFeedMock.updateAnswer(958e5); //usdc below lb
    //     usdtPriceFeedMock.updateAnswer(973e5); //usdt below depeg
    //     daiPriceFeedMock.updateAnswer(953e5); //dai below lb

    //     //redeeming 10% of the liquidity
    //     nstblHub.redeem(10 * _amount / 100, user1);
    //     vm.stopPrank();

    //     //redeemed only 10% of the liquidity
    //     assertApproxEqAbs(
    //         ((_amount * 8 / 100) * 980 / 958) / 10 ** 12,
    //         usdcBalBefore - IERC20Helper(USDC).balanceOf(address(nstblHub)),
    //         1,
    //         "check USDC balance"
    //     );
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 973) / 10 ** 12,
    //         usdtBalBefore - IERC20Helper(USDT).balanceOf(address(nstblHub)),
    //         1,
    //         "check USDT balance"
    //     );
    //     assertApproxEqAbs(
    //         ((_amount * 1 / 100) * 980 / 953),
    //         daiBalBefore - IERC20Helper(DAI).balanceOf(address(nstblHub)),
    //         1e12,
    //         "check DAI balance"
    //     );
    //     assertEq(nealthyBal - nstblToken.balanceOf(nealthyAddr), _amount / 10);
    // }

    // // such a case is prevented by backend.
    // // It always makes sure that input redeem amount never exceeds the available liquidity
    // function test_redeem_usdcDepeg_insuffLiquidity() external {
    //     uint256 _amount = 1e6 * 1e18;

    //     //noDepeg at the time of depeg
    //     usdcPriceFeedMock.updateAnswer(982e5);
    //     usdtPriceFeedMock.updateAnswer(99e6);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //first making a deposit
    //     _depositNSTBL(_amount);

    //     uint256 usdcBalBefore = nstblHub.stablesBalances(USDC);
    //     uint256 usdtBalBefore = nstblHub.stablesBalances(USDT);
    //     uint256 daiBalBefore = nstblHub.stablesBalances(DAI);
    //     vm.startPrank(nealthyAddr);

    //     //depeg at the time of redemption
    //     usdcPriceFeedMock.updateAnswer(971e5);
    //     usdtPriceFeedMock.updateAnswer(983e5);
    //     daiPriceFeedMock.updateAnswer(981e5);

    //     //redeeming 10% of the liquidity
    //     uint256 nstblBalBefore = nstblToken.balanceOf(nealthyAddr);
    //     nstblHub.redeem(_amount / 2, user1);
    //     vm.stopPrank();

    //     //redeemed 50% of the liquidity
    //     assertEq(nstblHub.stablesBalances(USDC), 0, "check USDC balance");
    //     assertEq(nstblHub.stablesBalances(USDT), 0, "check USDT balance");
    //     assertEq(nstblHub.stablesBalances(DAI), 0, "check DAI balance");
    //     assertEq(IERC20Helper(USDC).balanceOf(user1), usdcBalBefore);
    //     assertEq(IERC20Helper(USDT).balanceOf(user1), usdtBalBefore);
    //     assertEq(IERC20Helper(DAI).balanceOf(user1), daiBalBefore);
    //     assertEq(nstblBalBefore - nstblToken.balanceOf(nealthyAddr), _amount / 2, "check NSTBL balance");
    // }
}
