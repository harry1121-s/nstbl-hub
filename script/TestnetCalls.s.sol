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


contract TestnetCalls is Script, Test {

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
        _setStablesPrice(981e5, 983e5, 99e6);
        _removeShares();
        // _configureContracts();
        // _test_mint_stables();
        // _depositNSTBL(1e6*1e18);
        // _fetchDeployments();
        // _stakeNSTBL(owner, 3e5*1e18, 0);
        // _unstakeNSTBL(owner, 0);
        // // _redeemNSTBL(1e5*1e18, owner);
        // _redeemMaxNSTBL(owner);

    }

    function _deployAuxiliary() public {
        proxyAdmin = ProxyAdmin(0xee56dDA84d536533119d7757d7b7eC49b924aCA2);
        usdcPriceFeedMock = MockV3Aggregator(0xb81F3e3063daFC810e0e417E8e514D54334b9288);
        usdtPriceFeedMock = MockV3Aggregator(0x08E75AD5d76622bD5f2F8b3428713a134636fC11);
        daiPriceFeedMock = MockV3Aggregator(0x5008705B3563D718915Cf21188f2eB08511C1F7D);
        priceFeed = ChainLinkPriceFeed(0xfbf2d9F6a76E99FB45a0D9666AD04d06322B530C);
        poolProxy = 0x5F837a7aA34f0c26daFC17A3e230f6D5EA9B43b2;
    }

    function _deployMains() public {

        aclManager = ACLManager(0xb810bf8B3ac959FDe78E025334E80666c3aca40d);

        atvl = ATVL(0x2AC7EA1ba4d9948812E24C7486C63794034D9Eae);
                                            
        token_src = NSTBLToken(0x62d1346b3d94A6Bf296202486181Ad57dC6A70bf);

        loanManager = LoanManager(0xb3c16FbAE982a9F568eF1B9E79a57C123EfDC30e);

        stakePool = NSTBLStakePool(0xdd34D5D264996B6dc05e8bAAdCFE623B9F53B8b4);

        nstblHub = NSTBLHub(0x077feBee4ad852D29C67d9e0bc41de9e91248B41);

        hubViews = NSTBLHubViews(0x3bfdd2795752C8eb9fA81BeD4ddDDD6C79D985Aa);

    }

    function _removeShares() public {
        console.log("Pool Shares balance", Pool(poolProxy).balanceOf(poolProxy));
        console.log("Loan Manager Shares balance", Pool(poolProxy).balanceOf(address(loanManager)));
        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        vm.startBroadcast(pKey);
        Pool(poolProxy).removeShares(Pool(poolProxy).balanceOf(poolProxy), address(loanManager));
        console.log("Pool Shares balance", Pool(poolProxy).balanceOf(poolProxy));
        console.log("Loan Manager Shares balance", Pool(poolProxy).balanceOf(address(loanManager)));

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

    function _fetchDeployments() internal view{
        console.log("Token Supply", token_src.totalSupply());
        console.log("Owner Token balance", token_src.balanceOf(vm.addr(vm.envUint("DEV_PRIVATE_KEY"))));
        console.log("ATVL Token balance", token_src.balanceOf(address(atvl)));
        console.log("USDC hub balance", nstblHub.stablesBalances(USDC));
        console.log("USDT hub balance", nstblHub.stablesBalances(USDT));
        console.log("DAI hub balance", nstblHub.stablesBalances(DAI));
        (uint256 p1, uint256 p2, uint256 p3) = priceFeed.getLatestPrice();
        console.log("USDC Price", priceFeed.getLatestPrice(address(usdcPriceFeedMock)));
        console.log("USDT Price", priceFeed.getLatestPrice(address(usdtPriceFeedMock)));
        console.log("DAI Price", priceFeed.getLatestPrice(address(daiPriceFeedMock)));
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