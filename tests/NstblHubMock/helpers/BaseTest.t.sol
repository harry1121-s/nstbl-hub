// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

// import { Test, console } from "forge-std/Test.sol";
import { MockV3Aggregator } from "../../../modules/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { StakePoolMock } from "../../../contracts/mocks/StakePool/StakePoolMock.sol";
import { NSTBLTokenMock } from "../../../contracts/mocks/NSTBLTokenMock.sol";
import { ChainLinkPriceFeedMock } from "../../../contracts/mocks/chainlink/ChainlinkPriceFeedMock.sol";
import { NSTBLHub } from "../../../contracts/NSTBLHub.sol";
import { Atvl } from "../../../contracts/ATVL/atvl.sol";
import { eqLogic } from "../../../contracts/equilibriumLogic.sol";
import { eqLogicInternal } from "../../harness/eqLogicInternal.sol";
import { NSTBLHubInternal } from "../../harness/NSTBLHUBInternal.sol";
import { LoanManagerMock } from "../../../contracts/mocks/LoanManagerMock.sol";
import { Utils, IERC20Helper, IERC20 } from "./utils.sol";
// import { IERC20Helper } from "../../contracts/interfaces/IERC20Helper.sol";

contract BaseTest is Utils {
    StakePoolMock public stakePool;
    ChainLinkPriceFeedMock public priceFeed;
    NSTBLTokenMock public nstblToken;
    NSTBLHub public nstblHub;
    NSTBLHubInternal public nstblHubHarness;
    Atvl public atvl;
    eqLogic public eqlogic;
    LoanManagerMock public loanManager;
    eqLogicInternal public eqLogicHarness;

    MockV3Aggregator public usdcPriceFeedMock;
    MockV3Aggregator public usdtPriceFeedMock;
    MockV3Aggregator public daiPriceFeedMock;

    function setUp() public virtual {
        uint256 mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW");
        vm.selectFork(mainnetFork);

        usdcPriceFeedMock = new MockV3Aggregator(8, 1e8);
        usdtPriceFeedMock = new MockV3Aggregator(8, 1e8);
        daiPriceFeedMock = new MockV3Aggregator(8, 1e8);

        vm.startPrank(admin);
        priceFeed =
        new ChainLinkPriceFeedMock(address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock));
        nstblToken = new NSTBLTokenMock("NSTBL Token", "NSTBL", admin);

        stakePool = new StakePoolMock(
            admin,
            address(nstblToken)
        );
        atvl = new Atvl(
            admin
        );
        loanManager = new LoanManagerMock(admin);
        eqlogic = new eqLogic(
            address(priceFeed),
            address(loanManager),
            address(nstblToken),
            98e6,
            1e18
        );

        eqLogicHarness = new eqLogicInternal(
            address(priceFeed),
            address(loanManager),
            address(nstblToken),
            98e6,
            1e18
        );

        nstblHub = new NSTBLHub(
            nealthyAddr,
            address(nstblToken),
            address(stakePool),
            address(priceFeed),
            address(atvl),
            admin,
            address(loanManager),
            2*1e24
        );

        nstblHubHarness = new NSTBLHubInternal(
            nealthyAddr,
            address(nstblToken),
            address(stakePool),
            address(priceFeed),
            address(atvl),
            admin,
            address(loanManager),
            2*1e24
        );

        nstblToken.setAuthorizedCaller(address(nstblHub), true);
        nstblToken.setAuthorizedCaller(address(stakePool), true);
        nstblToken.setAuthorizedCaller(address(atvl), true);
        nstblToken.setAuthorizedCaller(address(eqlogic), true);

        atvl.init(address(nstblToken), 120);
        atvl.setAuthorizedCaller(address(nstblHub), true);
        stakePool.init(address(nstblHub));
        stakePool.configurePool(250, 30 days, 100);
        stakePool.configurePool(350, 60 days, 100);
        stakePool.configurePool(400, 90 days, 100);
        nstblHub.setSystemParams(dt, ub, lb, 1e3, 7e3);
        nstblHub.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);
        nstblHub.updateAssetAllocation(USDC, 8e4);
        nstblHub.updateAssetAllocation(USDT, 1e4);
        nstblHub.updateAssetAllocation(DAI, 1e4);

        nstblHubHarness.setSystemParams(dt, ub, lb, 1e3, 7e3);
        nstblHubHarness.updateAssetFeeds(
            [address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]
        );

        vm.stopPrank();
    }

    function _stakeNstbl(address _user, uint256 _amount, uint256 _poolId) internal {
        erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);
        vm.startPrank(nealthyAddr);
        nstblToken.approve(address(nstblHub), _amount);
        nstblHub.stake(_amount, _poolId, _user);
        vm.stopPrank();
    }
}
