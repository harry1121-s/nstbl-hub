// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { LoanManager } from "@nstbl-loan-manager/contracts/LoanManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPoolManager } from "@nstbl-loan-manager/contracts/interfaces/maple/IPoolManager.sol";
import { IWithdrawalManager, IWithdrawalManagerStorage } from "@nstbl-loan-manager/contracts/interfaces/maple/IWithdrawalManager.sol";
import { IPool } from "@nstbl-loan-manager/contracts/interfaces/maple/IPool.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract LoanManagerUtils {

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public loanManagerProxy;

    LoanManager public lmImpl1;
    LoanManager public loanManager;
    // Token public token;
    IERC20 public usdc;

    IERC20 public lusdc;

    IPool public usdcPool;
    IPoolManager public poolManagerUSDC;
    IWithdrawalManager public withdrawalManagerUSDC;
   
}
