pragma solidity 0.8.21;

import { console, Script } from "../modules/forge-std/src/Script.sol";
import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
// import { NSTBLHub, ubDeployer } from "../contracts/deployment/HubDeployer.sol";
import { NSTBLHub } from "../contracts/NSTBLHub.sol";

contract DeployContracts is Script, Test {

    ACLManager public aclManager;

    NSTBLToken public token_src;
    // NSTBLToken public token_dst;

    ATVL public atvl;

    //Proxy
    ProxyAdmin public proxyAdmin;

    ChainLinkPriceFeed public priceFeed;


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

    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public lmImplementation;
    address public spImplementation;
    address public hubImplementation;

    address public lmProxy;
    address public spProxy;
    address  public hubProxy;

    address usdcPriceFeed = address(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    address usdtPriceFeed = address(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    address daiPriceFeed = address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);

    address public MAPLE_USDC_CASH_POOL = address(0x50c375fb7dD7336d8928C98708F80b4EfcA549E4); //GOERLI TESTNET
    address public MAPLE_POOL_MANAGER_USDC = 0x219654A61a0BC394055652986BE403fa14405Bb8;

    LoanManagerDeployer lmDeployer;
    LoanManager loanManager;

    StakePoolDeployer spDeployer;
    NSTBLStakePool stakePool;

    // HubDeployer hubDeployer;
    NSTBLHub nstblHub;

    function run() external {

        uint256 pKey = vm.envUint("DEV_PRIVATE_KEY");
        address owner = vm.addr(pKey);
        console.log("Account: ", owner);

        vm.startBroadcast(pKey);
        console.log("GOERLI TESTNET DEPLOYMENT");

        aclManager = new ACLManager();

        atvl = new ATVL(address(aclManager));
                                            
        priceFeed = new ChainLinkPriceFeed(usdcPriceFeed, usdtPriceFeed, daiPriceFeed);

        token_src = new NSTBLToken(name, symbol, sharedDecimals, lzEndpoint_src, address(aclManager));

        // token_src.setAuthorizedChain(block.chainid, true);

        proxyAdmin = new ProxyAdmin(owner);

        lmDeployer = new LoanManagerDeployer(address(aclManager));
        spDeployer = new StakePoolDeployer(address(aclManager));
        // hubDeployer = new HubDeployer(owner);

        (lmImplementation, lmProxy) = lmDeployer.deployLoanManager(address(proxyAdmin), MAPLE_USDC_CASH_POOL);
        loanManager = LoanManager(lmProxy);

        (spImplementation, spProxy) = spDeployer.deployStakePool(address(proxyAdmin), address(token_src), address(loanManager), address(atvl));
        stakePool = NSTBLStakePool(spProxy);

        // (hubImplementation, hubProxy) = hubDeployer.deployHub(address(proxyAdmin), address(token_src), address(stakePool), address(priceFeed), address(atvl), address(loanManager), address(aclManager), 2e22);
        // nstblHub = NSTBLHub(hubProxy);

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

        console.log("ACL Manager Address-----------------", address(aclManager));
        console.log("ATVL Address------------------------", address(atvl));
        console.log("Chainlink PriceFeed Address---------", address(priceFeed));
        console.log("DEV TOKEN Address-------------------", address(token_src));
        console.log("Proxy Admin Address-----------------", address(proxyAdmin));
        console.log("LM Deployer Address-----------------", address(lmDeployer));
        console.log("SP Deployer Address-----------------", address(spDeployer));
        // console.log("HUB Deployer Address----------------", address(hubDeployer));
        console.log("LM Implementation Address-----------", lmImplementation);
        console.log("LM Proxy Address--------------------", lmProxy);
        console.log("SP Implementation Address-----------", spImplementation);
        console.log("SP Proxy Address--------------------", spProxy);
        console.log("HUB Implementation Address-----------", hubImplementation);
        console.log("HUB Proxy Address--------------------", hubProxy);

        console.log("----------------------------------------------------------------");

        console.log(loanManager.aclManager(), address(aclManager));
        console.log(loanManager.mapleUSDCPool(), MAPLE_USDC_CASH_POOL);
        console.log(loanManager.usdc(), USDC);
        console.log(loanManager.MAPLE_POOL_MANAGER_USDC(), MAPLE_POOL_MANAGER_USDC);
        console.log(uint256(vm.load(address(loanManager), bytes32(uint256(0)))), 1);
        console.log(loanManager.getVersion(), 1);
        console.log(loanManager.versionSlot(), 1);
        console.log(ERC20(address(loanManager.lUSDC())).name(), "Loan Manager USDC");

        console.log("----------------------------------------------------------------");

        console.log(stakePool.aclManager(), address(aclManager));
        console.log(stakePool.nstbl(), address(token_src));
        console.log(stakePool.atvl(), address(atvl));
        console.log(stakePool.loanManager(), address(loanManager));
        console.log(stakePool.poolProduct(), 1e18);
        console.log(stakePool.getVersion(), 1);
        console.log(uint256(vm.load(address(stakePool), bytes32(uint256(0)))), 1);

        console.log("----------------------------------------------------------------");

        console.log(nstblHub.nstblToken(), address(token_src));
        console.log(nstblHub.stakePool(), address(stakePool));
        console.log(nstblHub.chainLinkPriceFeed(), address(priceFeed));
        console.log(nstblHub.atvl(), address(atvl));
        console.log(nstblHub.loanManager(), address(loanManager));
        console.log(nstblHub.aclManager(), address(aclManager));
        console.log(nstblHub.eqTh(), 2 * 1e22);
        console.log(nstblHub.getVersion(), 1);

        vm.stopBroadcast();

    }

    function _deployContracts() public {

    }

    function _configureContracts() public {

    }

    function _deposit() internal {

    }

    function _redeem() internal {

    }

    function _stake() internal {

    }

    function _unstake() internal {

    }

    function _setPrices() internal {
        
    }
}