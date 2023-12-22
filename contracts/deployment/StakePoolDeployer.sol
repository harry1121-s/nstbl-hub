pragma solidity 0.8.21;

import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import { NSTBLStakePool } from "@nstbl-stake-pool/contracts/StakePool.sol";
import {
    TransparentUpgradeableProxy
} from "@nstbl-loan-manager/contracts/upgradeable/TransparentUpgradeableProxy.sol";

contract StakePoolDeployer {

    error NotAdmin(address caller);

    address aclManager;

    constructor(address aclManager_) {
        aclManager = aclManager_;
    }

   modifier onlyAdmin() {
        if (msg.sender != IACLManager(aclManager).admin()) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    function deployStakePool(address proxyAdmin_, address nstblToken_, address loanManager_, address atvl_) external onlyAdmin returns(address spImplementation_, address spProxy_) {
        NSTBLStakePool spImplementation = new NSTBLStakePool();
        bytes memory data = abi.encodeCall(
            spImplementation.initialize, (aclManager, nstblToken_, loanManager_, atvl_)
        );
        TransparentUpgradeableProxy stakePoolProxy = new TransparentUpgradeableProxy(address(spImplementation), proxyAdmin_, data);
        spImplementation_ = address(spImplementation);
        spProxy_ = address(stakePoolProxy);
    }

}