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
import { ATVL } from "../../../contracts/ATVL.sol";
import { IPoolManager } from "../../../contracts/interfaces/maple/IPoolManager.sol";
import { IPool } from "../../../contracts/interfaces/maple/IPool.sol";
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
    NSTBLHub public nstblHubImpl;
    NSTBLHub public nstblHub;
    ATVL public atvl;

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
    TransparentUpgradeableProxy public hubProxy;

    ChainLinkPriceFeed public priceFeed;

    //Mocks////////////////////////////////////////
    LZEndpointMock public LZEndpoint_src;
    LZEndpointMock public LZEndpoint_dst;


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

    
        atvl = new ATVL(
            address(aclManager)
        );

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

        //NSTBLHub
        nstblHubImpl = new NSTBLHub();
        data = abi.encodeCall(
            nstblHubImpl.initialize,
            (
                address(nstblToken),
                address(stakePool),
                address(priceFeed),
                address(atvl),
                address(loanManager),
                address(aclManager),
                2*1e24
            )
        );
        hubProxy = new TransparentUpgradeableProxy(address(nstblHubImpl), address(proxyAdmin), data);
        nstblHub = NSTBLHub(address(hubProxy));


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

        atvl.init(address(nstblToken), 1200);
        atvl.setAuthorizedCaller(address(nstblHub), true);
        stakePool.setupStakePool([300, 200, 100], [500, 500, 300], [30, 90, 180]);

        nstblHub.setSystemParams(dt, ub, lb, 7e3, 2e22);
        nstblHub.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);

        aclManager.setAuthorizedCallerHub(nealthyAddr, true);

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
        nstblHub.stake(_user, _amount, _trancheId);
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
        if(usdcAmt + usdtAmt + daiAmt == 0) {
            vm.expectRevert("HUB: Invalid Deposit");
        }
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopPrank();
    }

    function _randomizeDepositAmounts(uint256 _amount) internal view returns(uint256 usdcAmt, uint256 usdtAmt, uint256 daiAmt) {

        uint256 _randAmount = _amount*314159265358979323846; // multiplying with pi(without decimal)
        (usdcAmt, usdtAmt, daiAmt,) = nstblHub.previewDeposit(_amount / 1e18);

        if(uint(keccak256(abi.encode(_randAmount)))%2 == 0){
            usdcAmt += (1e3*usdcAmt/1e5);
        }
        else{
            usdcAmt -= (1e3*usdcAmt/1e5);
        }

        if((uint(keccak256(abi.encode(_randAmount)))>>10*8)%2 == 0){
            usdtAmt -= (1e3*usdtAmt/1e5);
        }
        else{
            usdtAmt += (1e3*usdtAmt/1e5);
        }

        if((uint(keccak256(abi.encode(_randAmount)))>>20*8)%2 == 0){
            daiAmt += (1e3*daiAmt/1e5);
        }
        else{
            daiAmt -= (1e3*daiAmt/1e5);
        }

    }

    function _unstakeNSTBL(address _user, uint8 _trancheId) internal {
        vm.prank(nealthyAddr);
        nstblHub.unstake(_user, _trancheId, destinationAddress);

    }

    function _getLiquidityCap(address _poolManager) internal view returns (uint256) {
        (, bytes memory val) = address(_poolManager).staticcall(abi.encodeWithSignature("liquidityCap()"));
        return uint256(bytes32(val));
    }

    function _getUpperBoundDeposit() internal view returns (uint256) {
        uint256 upperBound = _getLiquidityCap(MAPLE_POOL_MANAGER_USDC);
        uint256 totalAssets = IPool(MAPLE_USDC_CASH_POOL).totalAssets();
        console.log("Upper bound", (upperBound - totalAssets));
        return 100*(upperBound - totalAssets)/70;
    
    }
}
