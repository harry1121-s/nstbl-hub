// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { MockV3Aggregator } from "../../../modules/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { NSTBLStakePool } from "@nstbl-stake-pool/contracts/StakePool.sol";
import { NSTBLToken } from "@nstbl-token/contracts/NSTBLToken.sol";
import { LZEndpointMock } from "@layerzerolabs/contracts/lzApp/mocks/LZEndpointMock.sol";
import { ChainLinkPriceFeed } from "../../../contracts/chainlink/ChainlinkPriceFeed.sol";
import { ACLManager } from "@nstbl-acl-manager/contracts/ACLManager.sol";
import { NSTBLHub } from "../../../contracts/NSTBLHub.sol";
import { Atvl } from "../../../contracts/ATVL/atvl.sol";
import { NSTBLHubInternal } from "../../harness/NSTBLHUBInternal.sol";
import { IPoolManager } from "../../../contracts/interfaces/maple/IPoolManager.sol";
import { LoanManager } from "@nstbl-loan-manager/contracts/LoanManager.sol";
import { ProxyAdmin } from "../../../contracts/upgradeable/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "../../../contracts/upgradeable/TransparentUpgradeableProxy.sol";
import { IERC20, IERC20Helper } from "../../../contracts/interfaces/IERC20Helper.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BaseTest is Test {
    using SafeERC20 for IERC20Helper;
    //TokenSetup

    ACLManager public aclManager;
    NSTBLToken public token_src;
    NSTBLToken public token_dst;

    NSTBLToken public nstblToken;

    //NSTBLHubSetup
    NSTBLHub public nstblHub;
    Atvl public atvl;

    //LoanManager
    LoanManager public lmImplementation;
    LoanManager public loanManager;
    IPoolManager public poolManagerUSDC;
    address public lmLPToken;

    //StakePool
    NSTBLStakePool public spImplementation;
    NSTBLStakePool public stakePool;

    //Proxy
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public loanManagerProxy;
    TransparentUpgradeableProxy public stakePoolProxy;

    //Mocks////////////////////////////////////////
    LZEndpointMock public LZEndpoint_src;
    LZEndpointMock public LZEndpoint_dst;

    ChainLinkPriceFeed public priceFeed;

    NSTBLHubInternal public nstblHubHarness;

    MockV3Aggregator public usdcPriceFeedMock;
    MockV3Aggregator public usdtPriceFeedMock;
    MockV3Aggregator public daiPriceFeedMock;

    /*//////////////////////////////////////////////////////////////
    Testing constants
    //////////////////////////////////////////////////////////////*/

    uint16 chainId_src = 1;
    uint16 chainId_dst = 2;

    // Token details
    string public symbol = "NSTBL";
    string public name = "NSTBL Token";
    uint8 public sharedDecimals = 5;

    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public poolDelegateUSDC = 0x8c8C2431658608F5649B8432764a930c952d8A98;
    address public MAPLE_USDC_CASH_POOL = 0xfe119e9C24ab79F1bDd5dd884B86Ceea2eE75D92;
    address public MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;
    address public WITHDRAWAL_MANAGER_USDC = 0x1146691782c089bCF0B19aCb8620943a35eebD12;

    uint256 public dt = 98 * 1e6;
    uint256 public ub = 97 * 1e6;
    uint256 public lb = 96 * 1e6;

    /*//////////////////////////////////////////////////////////////
    Addresses for testing
    //////////////////////////////////////////////////////////////*/

    address public owner = vm.addr(123);
    address public deployer = vm.addr(456);
    // address public atvl = address(10);
    address public destinationAddress = vm.addr(123_444);

    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public user3 = vm.addr(3);
    address public user4 = vm.addr(4);
    address public compliance = vm.addr(5);
    address public MULTISIG = vm.addr(6);
    address public nealthyAddr = vm.addr(7);

    /*//////////////////////////////////////////////////////////////
    Setup
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        uint256 mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW");
        vm.selectFork(mainnetFork);

        // Deploy mock LZEndpoints
        LZEndpoint_src = new LZEndpointMock(chainId_src);
        LZEndpoint_dst = new LZEndpointMock(chainId_dst);

        //Deploy Mock price aggregators
        usdcPriceFeedMock = new MockV3Aggregator(8, 1e8);
        usdtPriceFeedMock = new MockV3Aggregator(8, 1e8);
        daiPriceFeedMock = new MockV3Aggregator(8, 1e8);

        vm.startPrank(deployer);
        aclManager = new ACLManager();

        priceFeed =
            new ChainLinkPriceFeed(address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock));

        // Deploy tokens
        token_src = new NSTBLToken(name, symbol, sharedDecimals, address(LZEndpoint_src), address(aclManager));
        token_dst = new NSTBLToken(name, symbol, sharedDecimals, address(LZEndpoint_dst), address(aclManager));
        nstblToken = token_src;

        // LayerZero configurations
        LZEndpoint_src.setDestLzEndpoint(address(token_dst), address(LZEndpoint_dst));
        LZEndpoint_dst.setDestLzEndpoint(address(token_src), address(LZEndpoint_src));

        bytes memory path_dst = abi.encodePacked(address(token_dst), address(token_src));
        bytes memory path_src = abi.encodePacked(address(token_src), address(token_dst));
        token_src.setTrustedRemote(chainId_dst, path_dst);
        token_dst.setTrustedRemote(chainId_src, path_src);

        token_src.setAuthorizedChain(block.chainid, true);

        // stakePool = new StakePoolMock(
        //     deployer,
        //     address(nstblToken)
        // );
        atvl = new Atvl(
            deployer
        );

        // loanManager = new LoanManagerMock(deployer);

        //LoanManager
        proxyAdmin = new ProxyAdmin(owner);
        lmImplementation = new LoanManager();
        bytes memory data = abi.encodeCall(lmImplementation.initialize, (address(aclManager), MAPLE_USDC_CASH_POOL));
        loanManagerProxy = new TransparentUpgradeableProxy(address(lmImplementation), address(proxyAdmin), data);
        loanManager = LoanManager(address(loanManagerProxy));

        //StakePool
        spImplementation = new NSTBLStakePool();
        data = abi.encodeCall(
            spImplementation.initialize, (address(aclManager), address(nstblToken), address(loanManager), address(atvl))
        );
        stakePoolProxy = new TransparentUpgradeableProxy(address(spImplementation), address(proxyAdmin), data);
        stakePool = NSTBLStakePool(address(stakePoolProxy));

        //nSTBLHub
        nstblHub = new NSTBLHub(
            address(nstblToken),
            address(stakePool),
            address(priceFeed),
            address(atvl),
            address(loanManager),
            address(aclManager),
            2*1e24
        );

        loanManager.updateNSTBLHUB(address(nstblHub));

        // Set authorized caller in ACLManager
        // Token
        aclManager.setAuthorizedCallerToken(address(nstblHub), true);
        aclManager.setAuthorizedCallerToken(address(atvl), true);
        aclManager.setAuthorizedCallerToken(address(stakePool), true);
        aclManager.setAuthorizedCallerToken(owner, true);
        aclManager.setAuthorizedCallerBlacklister(compliance, true);
        // StakePool
        aclManager.setAuthorizedCallerStakePool(address(nstblHub), true);
        //LoanManager
        aclManager.setAuthorizedCallerLoanManager(address(nstblHub), true);

        atvl.init(address(nstblToken));
        atvl.setAuthorizedCaller(address(nstblHub), true);
        stakePool.setupStakePool([300, 200, 100], [700, 500, 300], [30, 90, 180]);

        nstblHub.setSystemParams(dt, ub, lb, 1e3, 7e3);
        nstblHub.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);
        nstblHub.updateAssetAllocation(USDC, 8e4);
        nstblHub.updateAssetAllocation(USDT, 1e4);
        nstblHub.updateAssetAllocation(DAI, 1e4);

        aclManager.setAuthorizedCallerHub(nealthyAddr, true);

        //harness for testing internal functions
        nstblHubHarness = new NSTBLHubInternal(
            address(nstblToken),
            address(stakePool),
            address(priceFeed),
            address(atvl),
            address(loanManager),
            address(aclManager),
            2*1e24
        );

        nstblHubHarness.setSystemParams(dt, ub, lb, 1e3, 7e3);
        nstblHubHarness.updateAssetFeeds(
            [address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]
        );

        vm.stopPrank();

        lmLPToken = address(loanManager.lUSDC());

        //setting NSTBLHub as allowed lender
        poolManagerUSDC = IPoolManager(MAPLE_POOL_MANAGER_USDC);
        _setAllowedLender();
    }

    function _setAllowedLender() internal {
        bool out;
        vm.startPrank(poolDelegateUSDC);
        poolManagerUSDC.setAllowedLender(address(loanManager), true);
        (out,) =
            address(poolManagerUSDC).staticcall(abi.encodeWithSignature("isValidLender(address)", address(loanManager)));
        assertTrue(out);
        vm.stopPrank();
    }

    function _stakeNSTBL(address _user, uint256 _amount, uint8 _trancheId) internal {
        // Action = Stake
        vm.startPrank(nealthyAddr);
        IERC20Helper(address(nstblToken)).safeIncreaseAllowance(address(nstblHub), _amount);
        nstblHub.stake(_user, _amount, _trancheId, destinationAddress);
        vm.stopPrank();
    }

    function _depositNSTBL(uint256 _amount) internal {
        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;

        (usdcAmt, usdtAmt, daiAmt,) = nstblHub.previewDeposit(_amount / 1e18);
        deal(USDC, nealthyAddr, usdcAmt);
        deal(USDT, nealthyAddr, usdtAmt);
        deal(DAI, nealthyAddr, daiAmt);

        vm.startPrank(nealthyAddr);
        IERC20Helper(USDC).safeIncreaseAllowance(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).safeIncreaseAllowance(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).safeIncreaseAllowance(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopPrank();
    }

    function _unstakeNSTBL(address _user, uint8 _trancheId) internal {
        vm.prank(nealthyAddr);
        nstblHub.unstake(_user, _trancheId, destinationAddress);
    }
}
