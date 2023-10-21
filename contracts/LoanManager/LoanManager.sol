// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {
    IPool,
    IERC20Helper,
    IWithdrawalManagerStorage,
    IWithdrawalManager,
    TokenLP,
    LoanManagerStorage
} from "./LoanManagerStorage.sol";
/**
 * @title LoanManager contract for managing Maple Protocol loans
 * @author Angad Singh Agarwal, Harshit Singhal
 * @notice This contract is intended to be used by NSTBL hub and future nealthy products
 * @dev This contract allows NSTBL hub to deposit assets into Maple Protocol pools, request and redeem Maple Protocol tokens, and perform various other loan management operations.
 */

contract LoanManager is LoanManagerStorage {
    using SafeERC20 for IERC20Helper;
    using Address for address;

    uint256 private _locked = 1;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to ensure that only authorized callers can execute a function.
     */
    modifier authorizedCaller() {
        require(msg.sender == nstblHub, "Loan Manager: unAuth Hub");
        _;
    }

    /**
     * @dev Modifier to ensure that only the admin can execute a function.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "LM: unAuth Admin");
        _;
    }

    /**
     * @dev Modifier to validate input parameters.
     */
    modifier validInput(address _asset, uint256 _amount) {
        require(_asset != address(0), "LM: Invalid Target address");
        require(_amount > 0, "LM: Insufficient amount");
        _;
    }

    /**
     * @dev Modifier to validate asset addresses.
     */
    modifier validAsset(address _asset) {
        require(_asset != address(0), "LM: Invalid Target address");
        _;
    }

    /**
     * @dev Modifier to prevent reentrancy attacks.
     */
    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor to initialize the LoanManager contract.
     * @param _nstblHub The address of the Nealthy NSTBL Hub contract.
     * @param _admin The address of the admin for this contract.
     * @param _mapleUSDCPool The address of the Maple Protocol USDC pool.
     * @param _mapleUSDTPool The address of the Maple Protocol USDT pool.
     */
    constructor(address _nstblHub, address _admin, address _mapleUSDCPool, address _mapleUSDTPool) {
        nstblHub = _nstblHub;
        admin = _admin;
        mapleUSDCPool = _mapleUSDCPool;
        mapleUSDTPool = _mapleUSDTPool;
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        lUSDC = new TokenLP("Loan Manager USDC", "lUSDC", _admin);
        lUSDT = new TokenLP("Loan Manager USDT", "lUSDT", _admin);
        adjustedDecimals = lUSDC.decimals() - IPool(mapleUSDCPool).decimals();

        emit NSTBLHUBChanged(address(0), nstblHub);
        emit AdminChanged(address(0), admin);
    }

    /*//////////////////////////////////////////////////////////////
                            LP Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit assets into the Maple Protocol pool and mint LP tokens (lUSDC/lUSDT) to the NSTBL Hub.
     * @notice The LP tokens corresponding to the shares issued by the Maple Protocol pool are minted.
     * @param _asset The address of the asset to deposit. (USDC/USDT)
     * @param _amount The amount of the asset to deposit.
     */
    function deposit(address _asset, uint256 _amount) external authorizedCaller nonReentrant validAsset(_asset) {
        if (_asset == usdc) {
            _depositMapleCash(_amount, usdc, mapleUSDCPool, address(lUSDC), MAPLE_POOL_MANAGER_USDC);
        } else if (_asset == usdt) {
            _depositMapleCash(_amount, usdt, mapleUSDTPool, address(lUSDT), MAPLE_POOL_MANAGER_USDT);
        }
    }

    /**
     * @dev Request the redemption of LP tokens issued. (lUSDC/lUSDT)
     * @notice The shares corresponding to the LP tokens are requested for redemption from the Maple Protocol pool.
     * @param _asset The address of the asset to redeem. (USDC/USDT)
     * @param _lpTokens The amount of LP tokens to redeem.
     */
    function requestRedeem(address _asset, uint256 _lpTokens)
        external
        authorizedCaller
        nonReentrant
        validInput(_asset, _lpTokens)
    {
        if (_asset == usdc) {
            _requestRedeemMapleCash(_lpTokens, usdc, mapleUSDCPool, address(lUSDC));
        } else if (_asset == usdt) {
            _requestRedeemMapleCash(_lpTokens, usdt, mapleUSDTPool, address(lUSDT));
        }
    }

    /**
     * @dev Redeem LP tokens issued. (lUSDC/lUSDT)
     * @notice The shares corresponding to the LP tokens that were requested for redemption are redeemed from the Maple Protocol pool.
     * @notice The shares are burned in the Maple Protocol pool contract and the LP tokens are burned here.
     * @param _asset The address of the asset to redeem. (USDC/USDT)
     */
    function redeem(address _asset) external authorizedCaller nonReentrant validAsset(_asset) {
        require(awaitingRedemption[_asset], "LM: No redemption requested");
        if (_asset == usdc) {
            _redeemMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
        } else if (_asset == usdt) {
            _redeemMapleCash(usdt, mapleUSDTPool, address(lUSDT), MAPLE_WITHDRAWAL_MANAGER_USDT);
        }
    }

    /**
     * @dev Remove Locked Maple Shares (during request redemption).
     * @notice The shares corresponding to the LP tokens that were requested for redemption are removed from the Maple Protocol pool.
     * @notice The shares are transferred Maple Protocol's withdrawal manager contract back to Nealthy's loan Manager.
     * @param _asset The address of the asset. (USDC/USDT)
     */
    function remove(address _asset) external authorizedCaller nonReentrant validAsset(_asset) {
        require(awaitingRedemption[_asset], "LM: No Tokens to remove");
        if (_asset == usdc) {
            _removeMapleCash(usdc, mapleUSDCPool, address(lUSDC), MAPLE_WITHDRAWAL_MANAGER_USDC);
        } else if (_asset == usdt) {
            _removeMapleCash(usdt, mapleUSDTPool, address(lUSDT), MAPLE_WITHDRAWAL_MANAGER_USDT);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           LM Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to deposit assets into the Maple Protocol pool and mint LP tokens.
     * @param _amount The amount of the asset to deposit.
     * @param _asset The address of the asset being deposited.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _poolManager The address of the Maple Protocol pool manager contract.
     * @notice This function checks if the deposit amount is valid, transfers the assets from the sender to this contract, approves the pool to spend the assets, updates relevant accounting data, and emits a `Deposit` event.
     */
    function _depositMapleCash(uint256 _amount, address _asset, address _pool, address _lpToken, address _poolManager)
        internal
    {
        require(isValidDepositAmount(_amount, _pool, _poolManager), "LM: Invalid amount");
        uint256 lpTokens;
        uint256 sharesReceived;
        IERC20Helper(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Helper(_asset).safeIncreaseAllowance(_pool, _amount);

        totalAssetsReceived[_asset] += _amount;
        uint256 balBefore = IPool(_pool).balanceOf(address(this));
        IPool(_pool).deposit(_amount, address(this));
        sharesReceived = IPool(_pool).balanceOf(address(this)) - balBefore;
        totalSharesReceived[_asset] += sharesReceived;
        lpTokens = sharesReceived * 10 ** adjustedDecimals;
        totalLPTokensMinted[_lpToken] += lpTokens;
        IERC20Helper(_lpToken).mint(nstblHub, lpTokens);
        emit Deposit(_asset, _amount, lpTokens, sharesReceived);
    }

    /**
     * @dev Internal function to request the redemption of LP tokens issued. (lUSDC/lUSDT)
     * @param _lpTokens The amount of LP tokens to redeem.
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @notice This function checks if redemption is pending and if there are sufficient shares to redeem, records the escrowed shares, and emits a `RequestRedeem` event.
     */
    function _requestRedeemMapleCash(uint256 _lpTokens, address _asset, address _pool, address _lpToken) internal {
        require(!awaitingRedemption[_asset], "LM: Redemption Pending");
        require(IPool(_pool).balanceOf(address(this)) >= _lpTokens / 10 ** adjustedDecimals, "LM: Insufficient Shares");
        escrowedMapleShares[_lpToken] = IPool(_pool).requestRedeem(_lpTokens / 10 ** adjustedDecimals, address(this));
        awaitingRedemption[_asset] = true;
        emit RequestRedeem(_asset, _lpTokens, escrowedMapleShares[_lpToken]);
    }

    /**
     * @dev Internal function to Redeem LP tokens issued. (lUSDC/lUSDT)
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _withdrawManager The address of the withdrawal manager contract.
     * @notice This function redeems Maple Protocol tokens, burns the associated LP tokens, updates relevant accounting data, and emits a `Redeem` event.
     */
    function _redeemMapleCash(address _asset, address _pool, address _lpToken, address _withdrawManager) internal {
        uint256 exitCycleId = IWithdrawalManagerStorage(_withdrawManager).exitCycleId(address(this));
        (uint256 windowStart, uint256 windowEnd) = IWithdrawalManager(_withdrawManager).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares[_lpToken];

        require(block.timestamp >= windowStart && block.timestamp < windowEnd, "LM: Not in Window");

        uint256 stablesRedeemed = IPool(_pool).redeem(_shares, nstblHub, address(this));
        assetsRedeemed[_asset] += stablesRedeemed;
        escrowedMapleShares[_lpToken] = IWithdrawalManagerStorage(_withdrawManager).lockedShares(address(this));
        IERC20Helper(_lpToken).burn(nstblHub, (_shares - escrowedMapleShares[_lpToken]) * 10 ** adjustedDecimals);
        if (escrowedMapleShares[_lpToken] == 0) {
            awaitingRedemption[_asset] = false;
        }
        emit Redeem(_asset, _shares, assetsRedeemed[_asset]);
    }

    /**
     * @dev Internal function to remove locked Maple Shares.
     * @param _asset The address of the asset to redeem.
     * @param _pool The address of the Maple Protocol pool.
     * @param _lpToken The address of the LP token associated with the pool.
     * @param _withdrawManager The address of the withdrawal manager contract.
     * @notice This function transfers locked Maple Shares from Maple Protocol to loanManager, updates relevant accounting data, and emits a `Remove` event.
     */
    function _removeMapleCash(address _asset, address _pool, address _lpToken, address _withdrawManager) internal {
        uint256 exitCycleId = IWithdrawalManagerStorage(_withdrawManager).exitCycleId(address(this));
        (uint256 windowStart,) = IWithdrawalManager(_withdrawManager).getWindowAtId(exitCycleId);
        uint256 _shares = escrowedMapleShares[_lpToken];

        require(block.timestamp > windowStart, "LM: Redemption Pending");

        uint256 sharesRemoved = IPool(_pool).removeShares(_shares, address(this));
        escrowedMapleShares[_lpToken] -= sharesRemoved;

        if (escrowedMapleShares[_lpToken] == 0) {
            awaitingRedemption[_asset] = false;
        }

        emit Removed(_asset, _shares);
    }

    /*//////////////////////////////////////////////////////////////
                           LM Getter Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get the number of LP tokens pending redemption for a specific LP token.
     * @param _lpToken The address of the LP token for which you want to check pending redemptions.
     * @return The number of LP tokens pending redemption, adjusted to the contract's decimals.
     */
    function getLpTokensPendingRedemption(address _lpToken) external view returns (uint256) {
        return escrowedMapleShares[_lpToken] * 10 ** adjustedDecimals;
    }

    /**
     * @dev Get the total assets represented by a given amount of LP tokens for a specific asset.
     * @param _asset The address of the asset for which you want to convert LP tokens to assets.
     * @param _lpTokens The amount of LP tokens to convert.
     * @return The total assets represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported.
     */
    function getAssets(address _asset, uint256 _lpTokens)
        external
        view
        validInput(_asset, _lpTokens)
        returns (uint256)
    {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToAssets(_lpTokens / 10 ** adjustedDecimals);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToAssets(_lpTokens / 10 ** adjustedDecimals);
        }
        return ERR_CODE;
    }

    /**
     * @dev Get the total assets with unrealized losses(from Maple Protocol's loans) represented by a given amount of LP tokens for a specific asset.
     * @param _asset The address of the asset for which you want to convert LP tokens to assets with unrealized losses.
     * @param _lpTokens The amount of LP tokens to convert.
     * @return The total assets with unrealized losses represented by the LP tokens, adjusted to the contract's decimals, or an error code if the asset is not supported.
     */
    function getAssetsWithUnrealisedLosses(address _asset, uint256 _lpTokens)
        external
        view
        validInput(_asset, _lpTokens)
        returns (uint256)
    {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToExitAssets(_lpTokens / 10 ** adjustedDecimals);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToExitAssets(_lpTokens / 10 ** adjustedDecimals);
        }
        return ERR_CODE;
    }

    /**
     * @dev Get the number of shares (issued by Maple protocol pool to the Loan Manager) represented by a given amount of an asset.
     * @param _asset The address of the asset for which you want to convert an amount to shares.
     * @param _amount The amount of the asset to convert.
     * @return The number of shares represented by the amount of the asset, or an error code if the asset is not supported.
     */
    function getShares(address _asset, uint256 _amount) external view validInput(_asset, _amount) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToShares(_amount);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToShares(_amount);
        }
        return ERR_CODE;
    }

    /**
     * @dev Get the number of exit shares represented by a given amount of an asset.
     * @param _asset The address of the asset for which you want to convert an amount to exit shares.
     * @param _amount The amount of the asset to convert.
     * @return The number of exit shares represented by the amount of the asset, or an error code if the asset is not supported.
     */
    function getExitShares(address _asset, uint256 _amount)
        external
        view
        validInput(_asset, _amount)
        returns (uint256)
    {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).convertToExitShares(_amount);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).convertToExitShares(_amount);
        }
        return ERR_CODE;
    }

    /**
     * @dev Get the total unrealized losses (from Maple Protocol's loans) for a specific asset within the Maple Protocol pool.
     * @param _asset The address of the asset for which you want to retrieve unrealized losses.
     * @return The total unrealized losses for the asset, or an error code if the asset is not supported.
     */
    function getUnrealizedLossesMaple(address _asset) external view validAsset(_asset) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).unrealizedLosses();
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).unrealizedLosses();
        }
        return ERR_CODE;
    }

    /**
     * @dev Get the total amount for a specific asset within the Maple Protocol pool.
     * @param _asset The address of the asset for which you want to retrieve the total amount.
     * @return The total amount for the asset, or an error code if the asset is not supported.
     */
    function getTotalAssetsMaple(address _asset) external view validAsset(_asset) returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).totalAssets();
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).totalAssets();
        }
        return ERR_CODE;
    }

    /**
     * @dev Preview the redemption of assets based on the given asset and number of LP tokens.
     * @notice This function returns correct value only when a redemption has been requested and when called within the redemption window.
     * @param _asset The address of the asset for which you want to preview the redemption.
     * @param _lpTokens The number of LP tokens to be redeemed.
     * @return The previewed amount of redeemed assets, or an error code if the asset is not supported.
     */
    function previewRedeem(address _asset, uint256 _lpTokens) external view returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).previewRedeem(_lpTokens / 10 ** 12);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).previewRedeem(_lpTokens / 10 ** 12);
        }
        return ERR_CODE;
    }

    /**
     * @dev Preview the deposit of assets based on the given asset and amount.
     * @param _asset The address of the asset for which you want to preview the deposit.
     * @param _amount The amount of assets to be deposited.
     * @return The previewed amount of shares that would be minted to the Loan Manager, or an error code if the asset is not supported.
     */
    function previewDepositAssets(address _asset, uint256 _amount) external view returns (uint256) {
        if (_asset == usdc) {
            return IPool(mapleUSDCPool).previewDeposit(_amount);
        } else if (_asset == usdt) {
            return IPool(mapleUSDTPool).previewDeposit(_amount);
        }
        return ERR_CODE;
    }

    /**
     * @dev Check if a deposit amount is valid based on the liquidity cap and total assets in the Maple Protocol pool.
     * @param _amount The amount to deposit.
     * @param _pool The address of the Maple Protocol pool contract.
     * @param _poolManager The address of the Maple Protocol pool manager contract.
     * @return true if the deposit amount is valid; otherwise, false.
     */
    function isValidDepositAmount(uint256 _amount, address _pool, address _poolManager) public view returns (bool) {
        bytes memory val = _poolManager.functionStaticCall(abi.encodeWithSignature("liquidityCap()"));
        uint256 upperBound = uint256(bytes32(val));
        uint256 totalAssets = IPool(_pool).totalAssets();
        uint256 shares = IPool(_pool).previewDeposit(_amount);
        return (shares > 0) && (_amount < (upperBound - totalAssets)) ? true : false;
    }

    /*//////////////////////////////////////////////////////////////
                           LM Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set an authorized caller address for the Loan Manager contract.
     * @param _caller The address to be set as an authorized caller.
     * @notice This function can only be called by the admin of the Loan Manager contract.
     * @notice This function is used to update the authorized caller address for the Loan Manager contract.
     * Only the admin has the permission to call this function. The authorized caller is typically a trusted contract or entity
     * that can interact with the Loan Manager contract on behalf of the Maple Protocol, granting specific permissions.
     * @notice Use this function with caution, as it can grant or revoke important privileges to the designated caller.
     */
    function setAuthorizedCaller(address _caller) external onlyAdmin {
        require(_caller != address(0));
        address oldHub = nstblHub;
        nstblHub = _caller;
        emit NSTBLHUBChanged(oldHub, nstblHub);
    }

    /**
     * @dev updates admin address for the Loan Manager contract.
     * @param _admin The address to be set as the admin.
     * @notice This function can only be called by the admin of the Loan Manager contract.
     * @notice This function is used to update the admin address for the Loan Manager contract.
     * Only the admin has the permission to call this function. The admin is typically a trusted address or entity
     * that can update the access of authorized caller to the Loan Manager contract.
     * @notice Use this function with caution, as it can grant or revoke important privileges to the designated caller.
     */
    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0));
        address oldAdmin = admin;
        admin = _admin;
        emit AdminChanged(oldAdmin, admin);
    }
}
