pragma solidity 0.8.21;

// import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import { NSTBLHub } from "../NSTBLHub.sol";
import {
    TransparentUpgradeableProxy
} from "@nstbl-loan-manager/contracts/upgradeable/TransparentUpgradeableProxy.sol";

contract HubDeployer {

    error NotAdmin(address caller);

    address owner;
    // address aclManager;

    constructor(address owner_) {
        owner = owner_;
    }

    // modifier onlyAdmin() {
    //     if (msg.sender != IACLManager(aclManager).admin()) {
    //         revert NotAdmin(msg.sender);
    //     }
    //     _;
    // }

    function deployHub(address proxyAdmin_, address nstblToken_, address stakePool_, address priceFeed_, address atvl_, address loanManager_, address aclManager_, uint256 eqTh_) external returns(address hubImplementation_, address hubProxy_){
       require(msg.sender == owner);
       NSTBLHub hubImplementation = new NSTBLHub();
       bytes memory data = abi.encodeCall(
            hubImplementation.initialize,
            (
                nstblToken_,
                stakePool_,
                priceFeed_,
                atvl_,
                loanManager_,
                aclManager_,
                eqTh_
            )
        );
        TransparentUpgradeableProxy hubProxy = new TransparentUpgradeableProxy(address(hubImplementation), proxyAdmin_, data);

        hubImplementation_ = address(hubImplementation);
        hubProxy_ = address(hubProxy);
    }

}