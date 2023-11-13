# nSTBL Hub

## Overview
This repository contains the core contracts of the nSTBL V1 protocol that is the main entry point for the protocol. It handles deposit, redemption, stake and unstake. In addition to this, all the depeg risk hedging mechanisms are also contained here

| Contract | Description |
| -------- | ------- |
| [`NSTBLHub`](https://github.com/nealthy-labs/nSTBL_V1_Hub/blob/main/contracts/NSTBLHub.sol) | Contains the logic for the Loan Manager |
| [`NSTBLHUBStorage`](https://github.com/nealthy-labs/nSTBL_V1_Hub/blob/main/contracts/NSTBLHUBStorage.sol) | Contains the storage for the Loan Manager, decoupled to keep track of upgrades |
| [`INSTBLHub`](https://github.com/nealthy-labs/nSTBL_V1_Hub/blob/main/contracts/INSTBLHub.sol) | The interface for the Loan Manager contract |
| [`ChainlinkPriceFeed`](https://github.com/nealthy-labs/nSTBL_V1_Hub/blob/main/contracts/ChainlinkPriceFeed.sol) | The wrapper for chainlink price oracle |
| [`ATVL`](https://github.com/nealthy-labs/nSTBL_V1_Hubl/blob/main/contracts/ATVL.sol) | Contains the functionality for the ATVL which is a buffer for depeg offsets |
| [`TransparentUpgradeableProxy`](https://github.com/nealthy-labs/nSTBL_V1_Hub/blob/main/contracts/upgradeable/TransparentUpgradeableProxy.sol) | Transparent upgradeable proxy contract with minor change in constructor where we pass the address of proxy admin instead of deploying a new one |

## Dependencies/Inheritance
Contracts in this repo inherit and import code from:
- [`openzeppelin-contracts`](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [`chainlink`](https://github.com/smartcontractkit/chainlink.git)
- [`nSTBL_V1_ACLManager`](https://github.com/nealthy-labs/nSTBL_V1_ACLManager.git)
- [`nSTBL_V1_LoanManager`](https://github.com/nealthy-labs/nSTBL_V1_LoanManager.git)
- [`nSTBL_V1_nSTBLToken`](https://github.com/nealthy-labs/nSTBL_V1_nSTBLToken.git)
- [`nSTBL_V1_StakePool`](https://github.com/nealthy-labs/nSTBL_V1_StakePool.git)

## Setup
Run the command ```forge install``` before running any of the make commands. 

## Commands
To make it easier to perform some tasks within the repo, a few commands are available through a makefile:

### Build Commands
| Command | Action |
|---|---|
| `make test` | Run all tests |
| `make debug` | Run all tests with debug traces |
| `make testToken` | Run unit tests for LP Token |
| `make testStakePoolMock` | Run unit tests for the stake pool |
| `make clean` | Delete cached files |
| `make coverage` | Generate coverage report under coverage directory |
| `make slither` | Run static analyzer |

## About Nealthy
[Nealthy](https://www.nealthy.com) is a VARA regulated crypto asset management company. Nealthy provides on-chain index products for KYC/KYB individuals and institutions to invest in.
