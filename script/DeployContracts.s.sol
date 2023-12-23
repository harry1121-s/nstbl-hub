pragma solidity 0.8.21;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20, IERC20Helper } from "../contracts/interfaces/IERC20Helper.sol";
import { NSTBLToken } from "@nstbl-token/contracts/NSTBLToken.sol";
import { ChainLinkPriceFeed } from "../contracts/chainlink/ChainlinkPriceFeed.sol";
import { ACLManager } from "@nstbl-acl-manager/contracts/ACLManager.sol";
import { ProxyAdmin } from "@nstbl-loan-manager/contracts/upgradeable/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy
} from "@nstbl-loan-manager/contracts/upgradeable/TransparentUpgradeableProxy.sol";
import { ATVL } from "../contracts/ATVL.sol";
import { LoanManager, LoanManagerDeployer } from "../contracts/deployment/LoanManagerDeployer.sol";
import { NSTBLStakePool, StakePoolDeployer } from "../contracts/deployment/StakePoolDeployer.sol";
import { NSTBLHub } from "../contracts/NSTBLHub.sol";
import { MockV3Aggregator } from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { Pool } from "@maple-mocks/contracts/Pool.sol"; 
import { NSTBLHubViews } from "../contracts/NSTBLHubViews.sol";


contract DeployContracts is Script, Test {

    ACLManager public aclManager;

    NSTBLToken public token_src;
    // NSTBLToken public token_dst;

    ATVL public atvl;

    //ProxyAdmin
    ProxyAdmin public proxyAdmin;

    ChainLinkPriceFeed public priceFeed;

    MockV3Aggregator public usdcPriceFeedMock;
    MockV3Aggregator public usdtPriceFeedMock;
    MockV3Aggregator public daiPriceFeedMock;


    uint16 chainId_src = 10121; //GOERLI TESTNET
    // uint16 chainId_dst = ;

    address lzEndpoint_src = address(0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23); //GOERLI TESTNET
    // address lzEndpoint_dst = address();

    // Token details
    string public symbol = "DEVTOKEN";
    string public name = "DEV Token";
    uint8 public sharedDecimals = 5;

    uint256 public dt = 98 * 1e6;
    uint256 public ub = 97 * 1e6;
    uint256 public lb = 96 * 1e6;

    //goerli test tokens
    address USDC = address(0x94A4DC7C451Db157cd64E017CDF726501432b7e7);
    address USDT = address(0x6fa19Db493Ca53FB2E6Bc7b7Cee7ecC107DA3753);
    address DAI = address(0xf864EeC64EcD77E24d46aE841bf6fae855e61514);

    address public poolImplementation;
    address public lmImplementation;
    address public spImplementation;
    address public hubImplementation;

    address public poolProxy;
    address public lmProxy;
    address public spProxy;
    address  public hubProxy;

    LoanManagerDeployer lmDeployer;
    LoanManager loanManager;

    StakePoolDeployer spDeployer;
    NSTBLStakePool stakePool;

    NSTBLHub nstblHub;

    NSTBLHubViews public hubViews;


    function run() external {
        
        address owner = vm.addr(vm.envUint("DEV_PRIVATE_KEY"));
        _deployAuxiliary();
        _deployMains();
        _verifyDeployment();
        _getAddresses();
        _configureContracts();
        _test_mint_stables();
        _setStablesPrice(981e5, 983e5, 99e6);
        _depositNSTBL(1e6*1e18);
        _stakeNSTBL(owner, 3e5*1e18, 0);
        _unstakeNSTBL(owner, 0);
        // _redeemNSTBL(1e5*1e18, owner);
        _redeemMaxNSTBL(owner);

    }

    function _deployAuxiliary() public {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        
        proxyAdmin = new ProxyAdmin(vm.addr(pKey));

        usdcPriceFeedMock = new MockV3Aggregator(8, 1e8);
        usdtPriceFeedMock = new MockV3Aggregator(8, 1e8);
        daiPriceFeedMock = new MockV3Aggregator(8, 1e8);

        priceFeed =
            new ChainLinkPriceFeed(address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock));
        
        poolImplementation = address(new Pool());
        bytes memory data = abi.encodeCall(Pool(poolImplementation).initialize, (address(0x94A4DC7C451Db157cd64E017CDF726501432b7e7), "TUSDC CASH POOL", "TSUDC_CP"));
        poolProxy = address(new TransparentUpgradeableProxy(address(poolImplementation), address(proxyAdmin), data));

        vm.stopBroadcast();
    }

    function _deployMains() public {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");

        vm.startBroadcast(pKey);
        
        console.log("GOERLI TESTNET DEPLOYMENT");

        aclManager = new ACLManager();

        atvl = new ATVL(address(aclManager));
                                            
        token_src = new NSTBLToken(name, symbol, sharedDecimals, lzEndpoint_src, address(aclManager));

        // token_src.setAuthorizedChain(block.chainid, true);

        lmDeployer = new LoanManagerDeployer(address(aclManager));
        spDeployer = new StakePoolDeployer(address(aclManager));

        (lmImplementation, lmProxy) = lmDeployer.deployLoanManager(address(proxyAdmin), poolProxy, USDC);
        loanManager = LoanManager(lmProxy);

        (spImplementation, spProxy) = spDeployer.deployStakePool(address(proxyAdmin), address(token_src), address(loanManager), address(atvl));
        stakePool = NSTBLStakePool(spProxy);

        NSTBLHub hubImpl = new NSTBLHub();
        bytes memory data = abi.encodeCall(
            hubImpl.initialize,
            (
                address(token_src),
                address(stakePool),
                address(priceFeed),
                address(atvl),
                address(loanManager),
                address(aclManager),
                2e22
            )
        );
        hubProxy = address(new TransparentUpgradeableProxy(address(hubImpl), address(proxyAdmin), data));
        nstblHub = NSTBLHub(hubProxy);
        hubImplementation = address(hubImpl);

        hubViews = new NSTBLHubViews(address(nstblHub), address(stakePool), address(loanManager), address(priceFeed), address(token_src), dt);
        hubViews.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);

        vm.stopBroadcast();

    }

    function _verifyDeployment() public {
        assertEq(loanManager.aclManager(), address(aclManager));
        assertEq(loanManager.mapleUSDCPool(), poolProxy);
        assertEq(loanManager.usdc(), USDC);
        assertEq(loanManager.MAPLE_POOL_MANAGER_USDC(), poolProxy);
        assertEq(uint256(vm.load(address(loanManager), bytes32(uint256(0)))), 1);
        assertEq(loanManager.getVersion(), 1);
        assertEq(loanManager.versionSlot(), 1);
        assertEq(ERC20(address(loanManager.lUSDC())).name(), "Loan Manager USDC");
        assertEq(stakePool.aclManager(), address(aclManager));
        assertEq(stakePool.nstbl(), address(token_src));
        assertEq(stakePool.atvl(), address(atvl));
        assertEq(stakePool.loanManager(), address(loanManager));
        assertEq(stakePool.poolProduct(), 1e18);
        assertEq(stakePool.getVersion(), 1);
        assertEq(uint256(vm.load(address(stakePool), bytes32(uint256(0)))), 1);
        assertEq(nstblHub.nstblToken(), address(token_src));
        assertEq(nstblHub.stakePool(), address(stakePool));
        assertEq(nstblHub.chainLinkPriceFeed(), address(priceFeed));
        assertEq(nstblHub.atvl(), address(atvl));
        assertEq(nstblHub.loanManager(), address(loanManager));
        assertEq(nstblHub.aclManager(), address(aclManager));
        assertEq(nstblHub.eqTh(), 2 * 1e22);
        assertEq(nstblHub.getVersion(), 1);
    }

    function _getAddresses() public view{
        console.log("Proxy Admin Address--------------------", address(proxyAdmin));
        console.log("USDC PF Address------------------------", address(usdcPriceFeedMock));
        console.log("USDT PF Address------------------------", address(usdtPriceFeedMock));
        console.log("DAI PF Address-------------------------", address(daiPriceFeedMock));
        console.log("Chainlink PF Address-------------------", address(priceFeed));
        console.log("Pool Implementation Address------------", poolImplementation);
        console.log("Pool Proxy Address---------------------", poolProxy);
        // console.log("Pool Name------------------------------", Pool(poolProxy).name());
        // console.log("Pool Decimals--------------------------", Pool(poolProxy).decimals());

        console.log("ACL Manager Address--------------------", address(aclManager));
        console.log("ATVL Address---------------------------", address(atvl));
        console.log("TOKEN Address--------------------------", address(token_src));
        console.log("LM Deployer Address--------------------", address(lmDeployer));
        console.log("SP Deployer Address--------------------", address(spDeployer));
        console.log("LM Implementation Address--------------", lmImplementation);
        console.log("LM Proxy Address-----------------------", lmProxy);
        console.log("SP Implementation Address--------------", spImplementation);
        console.log("SP Proxy Address-----------------------", spProxy);
        console.log("HUB Implementation Address-------------", hubImplementation);
        console.log("HUB Proxy Address----------------------", hubProxy);
        console.log("HUB Views Address----------------------", address(hubViews));
    }

    function _configureContracts() public {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        address owner = vm.addr(pKey);

        token_src.setAuthorizedChain(block.chainid, true);
        loanManager.updateNSTBLHUB(address(nstblHub));

        // Set authorized caller in ACLManager
        // Token
        aclManager.setAuthorizedCallerToken(address(nstblHub), true);
        aclManager.setAuthorizedCallerToken(address(atvl), true);
        aclManager.setAuthorizedCallerToken(address(stakePool), true);
        aclManager.setAuthorizedCallerToken(owner, true);
        aclManager.setAuthorizedCallerBlacklister(owner, true);
        // StakePool
        aclManager.setAuthorizedCallerStakePool(address(nstblHub), true);
        //LoanManager
        aclManager.setAuthorizedCallerLoanManager(address(nstblHub), true);

        atvl.init(address(token_src), 1200);
        atvl.setAuthorizedCaller(address(nstblHub), true);
        stakePool.setupStakePool([300, 200, 100], [500, 500, 300], [30, 90, 180]);
        nstblHub.setSystemParams(dt, ub, lb, 7e3, 2e22);
        nstblHub.updateAssetFeeds([address(usdcPriceFeedMock), address(usdtPriceFeedMock), address(daiPriceFeedMock)]);
        aclManager.setAuthorizedCallerHub(owner, true);

        vm.stopBroadcast();

    }

    function _test_mint_stables() public {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        address owner = vm.addr(pKey);
        IERC20Helper(USDC).mint(owner, 1e6*1e6);
        assertEq(IERC20Helper(USDC).balanceOf(owner), 1e12, "check usdc minted");
        IERC20Helper(USDT).mint(owner, 1e6*1e6);
        assertEq(IERC20Helper(USDT).balanceOf(owner), 1e12, "check usdt minted");
        IERC20Helper(DAI).mint(owner, 1e6*1e18);
        assertEq(IERC20Helper(DAI).balanceOf(owner), 1e24, "check dai minted");
        vm.stopBroadcast();
    }

    function _depositNSTBL(uint256 amount_) internal {
        uint256 usdcAmt;
        uint256 usdtAmt;
        uint256 daiAmt;
        uint256 tBillAmt;
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        address owner = vm.addr(pKey);

        (usdcAmt, usdtAmt, daiAmt, tBillAmt) = nstblHub.previewDeposit(amount_ / 1e18);
        IERC20Helper(USDC).mint(owner, usdcAmt);
        IERC20Helper(USDT).mint(owner, usdtAmt);
        IERC20Helper(DAI).mint(owner, daiAmt);

        IERC20Helper(USDC).approve(address(nstblHub), usdcAmt);
        IERC20Helper(USDT).approve(address(nstblHub), usdtAmt);
        IERC20Helper(DAI).approve(address(nstblHub), daiAmt);
        nstblHub.deposit(usdcAmt, usdtAmt, daiAmt);
        vm.stopBroadcast();

        assertEq(token_src.balanceOf(owner), amount_, "check minted nstbl");
        assertEq(IERC20Helper(USDC).balanceOf(address(nstblHub)), usdcAmt- tBillAmt, "check usdc amt");
        assertEq(IERC20Helper(USDT).balanceOf(address(nstblHub)), usdtAmt, "check usdt amt");
        assertEq(IERC20Helper(DAI).balanceOf(address(nstblHub)), daiAmt, "check dai amt");
    }

    function _redeemNSTBL(uint256 amount_, address user_) internal {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(user_);
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(user_);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(user_);
        uint256 supplyBefore = token_src.totalSupply();
        nstblHub.redeem(amount_, user_);
        vm.stopBroadcast();
        console.log("USDC transferred: ", IERC20Helper(USDC).balanceOf(user_) - usdcBalBefore);
        console.log("USDT transferred: ", IERC20Helper(USDT).balanceOf(user_) - usdtBalBefore);
        console.log("DAI transferred: ", IERC20Helper(DAI).balanceOf(user_) - daiBalBefore);
        assertEq(token_src.totalSupply(), supplyBefore-amount_);

    }

    function _redeemMaxNSTBL(address user_) internal {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        uint256 usdcBalBefore = IERC20Helper(USDC).balanceOf(user_);
        uint256 usdtBalBefore = IERC20Helper(USDT).balanceOf(user_);
        uint256 daiBalBefore = IERC20Helper(DAI).balanceOf(user_);
        uint256 supplyBefore = token_src.totalSupply();
        uint256 maxAmount = hubViews.getMaxRedeemAmount();
        nstblHub.redeem(maxAmount, user_);
        vm.stopBroadcast();
        console.log("USDC transferred: ", IERC20Helper(USDC).balanceOf(user_) - usdcBalBefore);
        console.log("USDT transferred: ", IERC20Helper(USDT).balanceOf(user_) - usdtBalBefore);
        console.log("DAI transferred: ", IERC20Helper(DAI).balanceOf(user_) - daiBalBefore);
        console.log("USDC Hub balance: ", nstblHub.stablesBalances(USDC));
        console.log("USDT Hub balance: ", nstblHub.stablesBalances(USDT));
        console.log("DAI Hub balance: ", nstblHub.stablesBalances(DAI));
        assertEq(token_src.totalSupply(), supplyBefore-maxAmount);

    }

    function _stakeNSTBL(address user_, uint256 amount_, uint8 trancheId_) internal {
        
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        token_src.approve(address(nstblHub), amount_);
        nstblHub.stake(user_, amount_, trancheId_);
        vm.stopBroadcast();

        (uint256 amount,,,) = stakePool.getStakerInfo(user_, 0);

        assertEq(token_src.balanceOf(address(stakePool)), amount_, "check stake pool balance");
        assertEq(amount, amount_, "check owner staked amount");
    }

    function _unstakeNSTBL(address user_, uint8 trancheId_) internal {
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        uint256 nstblBalBefore = token_src.balanceOf(user_);
        uint256 userTokens = stakePool.getUserAvailableTokens(user_, trancheId_);
        nstblHub.unstake(user_, trancheId_, user_);
        assertEq(token_src.balanceOf(user_) - nstblBalBefore, 92*userTokens/100);
        vm.stopBroadcast();
        
    }

    function _setStablesPrice(int256 p1_, int256 p2_, int256 p3_) internal {
        usdcPriceFeedMock.updateAnswer(p1_);
        usdtPriceFeedMock.updateAnswer(p2_);
        daiPriceFeedMock.updateAnswer(p3_);
    }

}