pragma solidity 0.8.21;

import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import { LoanManager } from "@nstbl-loan-manager/contracts/LoanManager.sol";
import {
    TransparentUpgradeableProxy
} from "@nstbl-loan-manager/contracts/upgradeable/TransparentUpgradeableProxy.sol";

contract LoanManagerDeployer {

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

    function deployLoanManager(address proxyAdmin_, address mapleCashPool_) external onlyAdmin returns(address lmImplementation_, address lmProxy_){
        LoanManager lmImplementation = new LoanManager();
        bytes memory data = abi.encodeCall(lmImplementation.initialize, (aclManager, mapleCashPool_));
        TransparentUpgradeableProxy loanManagerProxy = new TransparentUpgradeableProxy(address(lmImplementation), proxyAdmin_, data);
        lmImplementation_ = address(lmImplementation);
        lmProxy_ = address(loanManagerProxy);
    }

}