// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.21;

// import { MockV3Aggregator } from "../../../modules/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
// // import { NSTBLTokenMock } from "../../../contracts/mocks/NSTBLTokenMock.sol";
// import { ChainLinkPriceFeedMock } from "../../../contracts/mocks/chainlink/ChainlinkPriceFeedMock.sol";
// import { NSTBLHub } from "../../../contracts/NSTBLHub.sol";
// // import { IATVL } from "../../../contracts/interfaces/IATVL.sol";
// // import { Atvl } from "../../../contracts/ATVL/atvl.sol";
// import { eqLogic } from "../../../contracts/equilibriumLogic.sol";
// import { eqLogicInternal } from "../../harness/eqLogicInternal.sol";
// // import { LoanManagerMock } from "../../../contracts/mocks/LoanManagerMock.sol";
// import { Utils, IERC20Helper, IERC20 } from "./utils.sol";
// import { BaseTestSP } from "@stakePool/tests/StakePool/helpers/BaseTestSP.t.sol";
// // import { IERC20Helper } from "../../contracts/interfaces/IERC20Helper.sol";

// contract BaseTestHub is BaseTestSP, Utils {
//     // StakePoolMock public stakePool;
//     ChainLinkPriceFeedMock public priceFeed;
//     // NSTBLTokenMock public nstblToken;
//     NSTBLHub public nstblHub;
//     // Atvl public atvl;
//     eqLogic public eqlogic;
//     // LoanManagerMock public loanManager;
//     eqLogicInternal public eqLogicHarness;

//     MockV3Aggregator public usdcPriceFeedMock;
//     MockV3Aggregator public usdtPriceFeedMock;
//     MockV3Aggregator public daiPriceFeedMock;

//     function setUp() public virtual override {
//         super.setUp();

//         usdcPriceFeedMock = new MockV3Aggregator(8, 1e8);
//         usdtPriceFeedMock = new MockV3Aggregator(8, 1e8);
//         daiPriceFeedMock = new MockV3Aggregator(8, 1e8);

//         vm.startPrank(admin);
//         priceFeed =
//         new ChainLinkPriceFeedMock(address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock));
//         // nstblToken = new NSTBLTokenMock("NSTBL Token", "NSTBL", admin);

//         // stakePool = new StakePoolMock(
//         //     admin,
//         //     address(nstblToken)
//         // );
//         // atvl = new Atvl(
//         //     admin
//         // );
//         // loanManager = new LoanManagerMock(admin);
//         // eqlogic = new eqLogic(
//         //     address(priceFeed),
//         //     address(loanManager),
//         //     address(nstblToken),
//         //     98e6,
//         //     1e18
//         // );

//         eqLogicHarness = new eqLogicInternal(
//             address(priceFeed),
//             address(loanManager),
//             address(nstblToken),
//             98e6,
//             1e18
//         );

//         nstblHub = new NSTBLHub(
//             nealthyAddr,
//             address(nstblToken),
//             address(stakePool),
//             address(priceFeed),
//             atvl,
//             admin
//         );
//         nstblToken.setAuthorizedCaller(address(nstblHub), true);
//         nstblToken.setAuthorizedCaller(address(stakePool), true);
//         nstblToken.setAuthorizedCaller(atvl, true);
//         nstblToken.setAuthorizedCaller(address(eqlogic), true);

//         Atvl.init(address(nstblToken), 120);
//         Atvl.setAuthorizedCaller(address(nstblHub), true);
//         stakePool.setAuthorizedCaller(address(nstblHub), true);
//         // stakePool.init(address(nstblHub));
//         // stakePool.configurePool(250, 30 days, 100);
//         // stakePool.configurePool(350, 60 days, 100);
//         // stakePool.configurePool(400, 90 days, 100);
//         nstblHub.setSystemParams(dt, ub, lb);
//         nstblHub.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);

//         vm.stopPrank();
//     }

//     function _stakeNstbl(address _user, uint256 _amount, uint256 _poolId) internal {
//         erc20_transfer(address(nstblToken), admin, nealthyAddr, _amount);
//         vm.startPrank(nealthyAddr);
//         nstblToken.approve(address(nstblHub), _amount);
//         nstblHub.stake(_amount, _poolId, _user);
//         vm.stopPrank();
//     }
// }
