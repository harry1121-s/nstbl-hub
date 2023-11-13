pragma solidity 0.8.21;

import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Test, console } from "forge-std/Test.sol";
import "./NSTBLHUBStorage.sol";

contract NSTBLHub is NSTBLHUBStorage {
    using SafeERC20 for IERC20Helper;

    uint256 private _locked = 1;

    struct localVars {
        bool belowDT;
        bool burnFromStakePool;
        uint256 burnAmount;
        uint256 stakePoolBurnAmount;
        uint256 assetBalance;
        uint256 assetProportion;
        uint256 assetRequired;
        uint256 remainingNstbl;
        uint256 adjustedDecimals;
    }

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == IACLManager(aclManager).admin(), "HUB::NOT_ADMIN");
        _;
    }

    modifier authorizedCaller() {
        require(IACLManager(aclManager).authorizedCallersHub(msg.sender), "HUB::UNAUTH");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "HUB::REENTRANT");
        _locked = 2;
        _;
        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address nstblToken_,
        address stakePool_,
        address chainLinkPriceFeed_,
        address atvl_,
        address loanManager_,
        address aclManager_,
        uint256 eqTh_
    ) {
        nstblToken = nstblToken_;
        stakePool = stakePool_;
        chainLinkPriceFeed = chainLinkPriceFeed_;
        atvl = atvl_;
        loanManager = loanManager_;
        aclManager = aclManager_;
        eqTh = eqTh_;
    }

    /*//////////////////////////////////////////////////////////////
    USER ENDPOINTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the amount of tokens that will be deposited according to the equilibrium ratio
     * @param depositAmount_ The amount of NSTBL to be minted
     * @notice the deposit Amount is given without decimals
     */
    function previewDeposit(uint256 depositAmount_)
        external
        view
        returns (uint256 _amt1, uint256 _amt2, uint256 _amt3, uint256 _tBillAmt)
    {
        (uint256 a1_, uint256 a2_, uint256 a3_) = _getSystemAllocation();
        uint256 tAlloc = a1_ + a2_ + a3_;
        _amt1 = a1_ * depositAmount_ * 10 ** IERC20Helper(USDC).decimals() / tAlloc;
        _amt2 = a2_ * depositAmount_ * 10 ** IERC20Helper(USDT).decimals() / tAlloc;
        _amt3 = a3_ * depositAmount_ * 10 ** IERC20Helper(DAI).decimals() / tAlloc;
        _tBillAmt = 7e3 * _amt1 / a1_;
    }

    function deposit(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_) external authorizedCaller {
        (uint256 a1_, uint256 a2_, uint256 a3_) = _validateSystemAllocation(usdcAmt_, usdtAmt_, daiAmt_);
        _checkEquilibrium(a1_, a2_, a3_, usdcAmt_, usdtAmt_, daiAmt_);

        //Deposit required Tokens
        IERC20Helper(USDC).safeTransferFrom(msg.sender, address(this), usdcAmt_);
        usdcDeposited += usdcAmt_;
        if (a2_ != 0) {
            IERC20Helper(USDT).safeTransferFrom(msg.sender, address(this), usdtAmt_);
            usdtDeposited += usdtAmt_;
        }
        if (a3_ != 0) {
            IERC20Helper(DAI).safeTransferFrom(msg.sender, address(this), daiAmt_);
            daiDeposited += daiAmt_;
        }
        IStakePool(stakePool).updatePoolFromHub(false, 0, 7e3 * usdcAmt_ / a1_);
        _investUSDC(7e3 * usdcAmt_ / a1_);
        if (IERC20Helper(nstblToken).totalSupply() == 0) {
            IStakePool(stakePool).updateMaturityValue();
        }
        IERC20Helper(nstblToken).mint(msg.sender, (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_);
    }

    function redeem(uint256 amount_, address user_) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(); //usdc
        if (p1 > dt && p2 > dt && p3 > dt) {
            redeemNormal(amount_);
        } else {
            redeemForNonStaker(amount_, user_);
        }
    }

    function unstake(address user_, uint8 trancheId_, address lpOwner_) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        if (p1 > dt && p2 > dt && p3 > dt) {
            unstakeNstbl(user_, trancheId_, false, lpOwner_);
        } else {
            unstakeAndRedeemNstbl(user_, trancheId_, lpOwner_);
        }
    }

    function stake(address user_, uint256 amount_, uint8 trancheId_, address destAddress_)
        external
        authorizedCaller
        nonReentrant
    {
        require(
            amount_ + IERC20Helper(nstblToken).balanceOf(stakePool) <= 40 * IERC20Helper(nstblToken).totalSupply() / 100,
            "HUB: STAKE_LIMIT_EXCEEDED"
        );
        IStakePool(stakePool).stake(user_, amount_, trancheId_, destAddress_);
        INSTBLToken(nstblToken).sendOrReturnPool(msg.sender, stakePool, amount_);
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN ONLY
    //////////////////////////////////////////////////////////////*/

    function updateAssetAllocation(address asset_, uint256 allocation_) external onlyAdmin {
        assetAllocation[asset_] = allocation_;
    }

    function updateAssetFeeds(address[3] memory assetFeeds_) external onlyAdmin {
        assetFeeds[0] = assetFeeds_[0];
        assetFeeds[1] = assetFeeds_[1];
        assetFeeds[2] = assetFeeds_[2];
    }

    /**
     * @dev Sets the system Params for the Hub
     * @param dt_ The depeg threshold
     * @param ub_ The upper bound
     * @param lb_ The lower bound
     * @param liquidPercent_ The liquid assets percent
     * @param tBillPercent_ The tBill assets percent
     * @param eqTh_ The equilibrium threshold
     */
    function setSystemParams(uint256 dt_, uint256 ub_, uint256 lb_, uint256 liquidPercent_, uint256 tBillPercent_, uint256 eqTh_)
        external
        onlyAdmin
    {
        dt = dt_;
        ub = ub_;
        lb = lb_;
        liquidPercent = liquidPercent_;
        tBillPercent = tBillPercent_;
        eqTh = eqTh_;
    }

    /**
     * @dev Processes TBill withdraw from loan manager
     */
    function processTBillWithdraw() external authorizedCaller returns (uint256) {
        require(ILoanManager(loanManager).awaitingRedemption(), "HUB: No redemption requested");
        return _redeemTBill();
    }


    /*//////////////////////////////////////////////////////////////
    INTERNALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Validates the system allocation according to the system state
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @notice returns the system allocations for USDC, USDT and DAI
     */
    function _validateSystemAllocation(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_)
        internal
        view
        returns (uint256 a1_, uint256 a2_, uint256 a3_)
    {
        (a1_, a2_, a3_) = _getSystemAllocation();
        require(a2_ == 0 ? usdtAmt_ == 0 : true, "HUB: Invalid Deposit"); //add this edge case
        require(a3_ == 0 ? daiAmt_ == 0 : true, "HUB: Invalid Deposit");
        require(usdcAmt_ + usdtAmt_ + daiAmt_ != 0, "HUB: Invalid Deposit");
    }

    /**
     * @dev Returns the system allocation according to the system state
     * @notice returns the system allocations for USDC, USDT and DAI
     */
    function _getSystemAllocation() internal view returns (uint256 a1_, uint256 a2_, uint256 a3_) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        require(p1 > dt, "HUB: Invalid Deposit");

        if (p2 > dt && p3 > dt) {
            a1_ = 8e3;
            a2_ = 1e3;
            a3_ = 1e3;
        } else if (p2 > dt && p3 <= dt) {
            a1_ = 85e2;
            a2_ = 15e2;
            a3_ = 0;
        } else if (p2 <= dt && p3 > dt) {
            a1_ = 85e2;
            a2_ = 0;
            a3_ = 15e2;
        } else {
            a1_ = 10e3;
            a2_ = 0;
            a3_ = 0;
        }
    }

    /**
     * @dev Validates the system equilibrium
     * @param a1_ The system allocation for USDC
     * @param a2_ The system allocation for USDT
     * @param a3_ The system allocation for DAI
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @notice checks the equilibrium using coverage ratio of each asset
     */
    function _checkEquilibrium(
        uint256 a1_,
        uint256 a2_,
        uint256 a3_,
        uint256 usdcAmt_,
        uint256 usdtAmt_,
        uint256 daiAmt_
    ) internal view {
        uint256 tAlloc = a1_ + a2_ + a3_;
        uint256[] memory balances = _getAssetBalances();
        uint256 tvlOld = balances[0] + balances[1] + balances[2];
        uint256 tvlNew = tvlOld + (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_;

        uint256[] memory cr = new uint256[](3);
        uint256 oldEq;
        if (tvlOld != 0) {
            cr[0] = a1_ != 0 ? (balances[0] * 1e12 * tAlloc * precision) / (a1_ * tvlOld) : 0;
            cr[1] = a2_ != 0 ? (balances[1] * 1e12 * tAlloc * precision) / (a2_ * tvlOld) : 0;
            cr[2] = a3_ != 0 ? (balances[2] * tAlloc * precision) / (a3_ * tvlOld) : 0;
            oldEq = _calcEq(cr[0], cr[1], cr[2]);
        }
        else{
            oldEq = 0;
        }

        cr[0] = a1_ != 0 ? ((balances[0] + usdcAmt_) * 1e12 * tAlloc * precision) / (a1_ * tvlNew) : 0;
        cr[1] = a2_ != 0 ? ((balances[1] + usdtAmt_) * 1e12 * tAlloc * precision) / (a2_ * tvlNew) : 0;
        cr[2] = a3_ != 0 ? ((balances[2] + daiAmt_) * tAlloc * precision) / (a3_ * tvlNew) : 0;

        uint256 newEq = _calcEq(cr[0], cr[1], cr[2]);

        if (oldEq == 0) {
            require(newEq < eqTh, "HUB::Deposit Not Allowed");
        } else {
            require(newEq <= oldEq || newEq < eqTh, "HUB::Deposit Not Allowed");
        }
    }

    /**
     * @dev Calculates the equilibrium according to the coverage ratio of each asset
     * @param cr1_ The coverage ratio of USDC
     * @param cr2_ The coverage ratio of USDT
     * @param cr3_ The coverage ratio of DAI
     * @notice returns the calculated equilibrium
     */
    function _calcEq(uint256 cr1_, uint256 cr2_, uint256 cr3_) internal view returns (uint256 eq_) {
        eq_ = (_modSub(cr1_) + _modSub(cr2_) + _modSub(cr3_)) / 3;
    }

    function _modSub(uint256 a_) internal view returns (uint256) {
        if (a_ != 0) {
            return a_ > precision ? a_ - precision : precision - a_;
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns the system balances for USDC< USDT, DAI
     */
    function _getAssetBalances() internal view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ILoanManager(loanManager).getMaturedAssets() + usdcDeposited * 1e12;
        balances[1] = usdtDeposited * 1e12;
        balances[2] = daiDeposited;

        return balances;
    }

    /**
     * @dev Invests USDC in the loan manager
     * @param amt_ The amount of USDC to be invested
     */
    function _investUSDC(uint256 amt_) internal {
        usdcInvested += amt_;
        IERC20Helper(USDC).safeIncreaseAllowance(loanManager, amt_);
        ILoanManager(loanManager).deposit(amt_);
    }

    /**
     * @dev Redeems NSTBL for a non-staker in non-depeg scenario
     * @param amount_ The amount of NSTBL to be redeemed
     */
    function redeemNormal(uint256 amount_) internal {
        uint256 liquidTokens = liquidPercent * amount_ / 1e4;
        uint256 tBillTokens = tBillPercent * amount_ / 1e4;
        uint256 availAssets;
        uint256 assetsLeft = amount_;
        uint256 adjustedDecimals;
        IERC20Helper(nstblToken).burn(msg.sender, amount_);
        for (uint256 i = 0; i < assets.length; i++) {
            adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(assets[i]).decimals();
            if (i == 0) {
                availAssets = (liquidTokens + tBillTokens) / 10 ** adjustedDecimals
                    <= IERC20Helper(assets[i]).balanceOf(address(this))
                    ? liquidTokens + tBillTokens
                    : IERC20Helper(assets[i]).balanceOf(address(this));
            } else {
                availAssets = liquidTokens / 10 ** adjustedDecimals <= IERC20Helper(assets[i]).balanceOf(address(this))
                    ? liquidTokens
                    : IERC20Helper(assets[i]).balanceOf(address(this));
            }
            IERC20Helper(assets[i]).safeTransfer(msg.sender, availAssets / 10 ** adjustedDecimals);
            assetsLeft -= availAssets;
        }
        requestTBillWithdraw(tBillTokens);
    }

    /**
     * @dev Unstakes NSTBL for staker in non-depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param depeg_ The depeg status of the system
     * @param lpOwner_ The address of the LP owner
     */
    function unstakeNstbl(address user_, uint8 trancheId_, bool depeg_, address lpOwner_) internal {
        uint256 tokensUnstaked = IStakePool(stakePool).unstake(user_, trancheId_, depeg_, lpOwner_);
        INSTBLToken(nstblToken).sendOrReturnPool(stakePool, msg.sender, tokensUnstaked);
    }
    /**
     * @dev Unstakes and redeems NSTBL for staker in depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param lpOwner_ The address of the LP owner
     * @notice The NSTBL amount is redeemed till it covers the failing stablecoins, then the remaining NSTBL is unstaked and transferred to staker
     */
    function unstakeAndRedeemNstbl(address user_, uint8 trancheId_, address lpOwner_) internal {
        (address[] memory failedAssets_, uint256[] memory failedAssetsPrice_) =
            _failedAssetsOrderWithPrice(_noOfFailedAssets());
        (address[] memory assets_, uint256[] memory _assetAmounts, uint256 unstakeBurnAmount_, uint256 burnAmount_) =
            _getStakerRedeemParams(user_, trancheId_, failedAssets_, failedAssetsPrice_);
        _unstakeAndBurnNstbl(user_, trancheId_, lpOwner_, unstakeBurnAmount_);
        _burnNstblFromAtvl(burnAmount_);
        for (uint256 i = 0; i < assets_.length; i++) {
            if (assets_[i] != address(0)) {
                IERC20Helper(assets_[i]).safeTransfer(msg.sender, _assetAmounts[i]);
            }
        }
    }

    /**
     * @dev Calculates redeem parameters for staker in depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param failedAssets_ array of all the failed assets
     * @param failedAssetsPrice_ array of all the failed assets price
     * @notice Returns the array of assets, array of asset amounts, unstake burn amount and  atvl burn amount
     */
    function _getStakerRedeemParams(
        address user_,
        uint8 trancheId_,
        address[] memory failedAssets_,
        uint256[] memory failedAssetsPrice_
    ) internal view returns (address[] memory, uint256[] memory, uint256 unstakeBurnAmount_, uint256 burnAmount_) {
        address[] memory assets_ = new address[](failedAssets_.length);
        uint256[] memory assetAmount_ = new uint256[](failedAssets_.length);
        uint256 assetsLeft = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_) * precision;
        uint256 redeemableNstbl;
        uint256 assetBalance;
        uint256 assetRequired;
        uint256 targetPrice;
        uint256 adjustedDecimals;
        for (uint256 i = 0; i < failedAssets_.length; i++) {
            if (failedAssetsPrice_[i] > ub) {
                targetPrice = dt;
            } else {
                targetPrice = failedAssetsPrice_[i] + 4e6;
            }

            assets_[i] = failedAssets_[i];
            adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(failedAssets_[i]).decimals();
            assetRequired = assetsLeft * targetPrice / (failedAssetsPrice_[i] * 10 ** adjustedDecimals);
            assetBalance = IERC20Helper(failedAssets_[i]).balanceOf(address(this)) * precision;

            if (assetRequired <= assetBalance) {
                assetAmount_[i] = assetRequired / precision;
                unstakeBurnAmount_ += (assetsLeft / precision);

                burnAmount_ += ((assetRequired * 10 ** adjustedDecimals - assetsLeft) / precision);
                assetsLeft -= assetsLeft;
                break;
            } else {
                redeemableNstbl = assetBalance * 10 ** adjustedDecimals * failedAssetsPrice_[i] / targetPrice;

                assetAmount_[i] = assetBalance / precision;
                unstakeBurnAmount_ += redeemableNstbl / precision;

                burnAmount_ += ((assetBalance * 10 ** adjustedDecimals) - redeemableNstbl) / precision;
                assetsLeft -= redeemableNstbl;
            }
        }

        return (assets_, assetAmount_, unstakeBurnAmount_, burnAmount_);
    }

    /**
     * @dev Unstakes and burn NSTBL for stakers in depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param lpOwner_ The address of the LP owner
     * @param unstakeBurnAmount_ The amount of NSTBL to be burned
     * @notice Unstaked the user's NSTBL and burns the required amount of NSTBL
     */
    function _unstakeAndBurnNstbl(address user_, uint8 trancheId_, address lpOwner_, uint256 unstakeBurnAmount_)
        internal
    {
        uint256 unstakedTokens = IStakePool(stakePool).unstake(user_, trancheId_, true, lpOwner_);
        IERC20Helper(nstblToken).burn(stakePool, unstakeBurnAmount_);
        INSTBLToken(nstblToken).sendOrReturnPool(stakePool, msg.sender, unstakedTokens - unstakeBurnAmount_);
    }

    /**
     * @dev Burns NSTBL from ATVL
     * @param burnAmount_ The amount of NSTBL to be burned
     */
    function _burnNstblFromAtvl(uint256 burnAmount_) internal {
        atvlBurnAmount += burnAmount_;
        IATVL(atvl).burnNstbl(burnAmount_);
    }

    /**
     * @dev Redeems NSTBL for non-stakers in depeg scenario
     * @param amount_ The amount of NSTBL to be redeemed
     * @param user_ The address of the user
     */
    function redeemForNonStaker(uint256 amount_, address user_) internal {
        localVars memory vars;
        uint256 precisionAmount = amount_ * precision;

        IERC20Helper(nstblToken).burn(msg.sender, amount_);
        (address[] memory sortedAssets, uint256[] memory sortedAssetsPrice) = _getSortedAssetsWithPrice();
        for (uint256 i = 0; i < sortedAssets.length; i++) {
            if (sortedAssetsPrice[i] <= dt) {
                vars.belowDT = true;
                if (sortedAssetsPrice[i] <= lb) {
                    vars.burnFromStakePool = true;
                } else {
                    vars.burnFromStakePool = false;
                }
            } else {
                vars.belowDT = false;
            }

            vars.assetBalance = IERC20Helper(sortedAssets[i]).balanceOf(address(this)) * precision;
            vars.adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(sortedAssets[i]).decimals();
            if (!vars.belowDT) {
                vars.assetRequired = (assetAllocation[sortedAssets[i]] * precisionAmount / 1e5) + vars.remainingNstbl;
                vars.remainingNstbl = _transferNormal(
                    user_, sortedAssets[i], vars.assetRequired, vars.assetBalance, vars.adjustedDecimals
                );
            } else {
                vars.assetProportion = (
                    (assetAllocation[sortedAssets[i]] * precisionAmount / 1e5) + vars.remainingNstbl
                ) / 10 ** vars.adjustedDecimals;
                vars.assetRequired = vars.assetProportion * dt / sortedAssetsPrice[i];

                (vars.remainingNstbl, vars.burnAmount) = _transferBelowDepeg(
                    user_,
                    sortedAssets[i],
                    vars.assetProportion,
                    vars.assetRequired,
                    vars.assetBalance,
                    vars.adjustedDecimals,
                    vars.burnAmount,
                    sortedAssetsPrice[i]
                );

                vars.stakePoolBurnAmount += vars.burnFromStakePool
                    ? _stakePoolBurnAmount(vars.assetRequired, vars.assetProportion)
                    : 0;
            }
        }
        _burnNstblFromAtvl((vars.burnAmount - vars.stakePoolBurnAmount));
        _burnNstblFromStakePool(vars.stakePoolBurnAmount);
        requestTBillWithdraw(amount_ * 7e4 / 1e5);
    }

    /**
     * @dev transfers assets to non-stakers if the asset is above depeg threshold
     * @param user_ The address of the user
     * @param asset_ The address of the asset
     * @param assetRequired_ The amount of asset required
     * @param assetBalance_ The balance of the asset
     * @param adjustedDecimals_ The adjusted decimals of the asset
     */
    function _transferNormal(
        address user_,
        address asset_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_
    ) internal returns (uint256 _remainingNstbl) {
        if (assetRequired_ <= assetBalance_ * 10 ** adjustedDecimals_) {
            IERC20Helper(asset_).safeTransfer(user_, assetRequired_ / (precision * 10 ** adjustedDecimals_));
            _remainingNstbl = 0;
        } else {
            IERC20Helper(asset_).safeTransfer(user_, assetBalance_ / precision);

            _remainingNstbl = (assetRequired_ - assetBalance_ * 10 ** adjustedDecimals_);
        }
    }

    /**
     * @dev transfers assets to non-stakers if the asset is below depeg threshold
     * @param user_ The address of the user
     * @param asset_ The address of the asset
     * @param assetProportion_ The proportion of asset required
     * @param assetRequired_ The amount of asset required
     * @param assetBalance_ The balance of the asset
     * @param adjustedDecimals_ The adjusted decimals of the asset
     * @param burnAmount_ The amount of NSTBL to be burned
     * @param assetPrice_ The price of the asset
     */
    function _transferBelowDepeg(
        address user_,
        address asset_,
        uint256 assetProportion_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_,
        uint256 burnAmount_,
        uint256 assetPrice_
    ) internal returns (uint256, uint256) {
        uint256 _remainingNstbl;
        uint256 redeemableNstbl;
        if (assetRequired_ <= assetBalance_) {
            IERC20Helper(asset_).safeTransfer(user_, assetRequired_ / precision);

            _remainingNstbl = 0;
            burnAmount_ += (assetRequired_ - assetProportion_) * 10 ** adjustedDecimals_ / precision;
        } else {
            redeemableNstbl = assetBalance_ * assetPrice_ / dt;
            burnAmount_ += (assetBalance_ - redeemableNstbl) * 10 ** adjustedDecimals_ / precision;
            _remainingNstbl = (assetProportion_ - redeemableNstbl) * 10 ** adjustedDecimals_;
            IERC20Helper(asset_).safeTransfer(user_, assetBalance_ / precision);
        }
        return (_remainingNstbl, burnAmount_);
    }

    /**
     * @dev Calculates the amount of NSTBL to be burned from stake pool in case asset is below lowerBound
     * @param assetRequired_ The amount of asset required
     * @param assetProportion_ The proportion of asset required
     */
    function _stakePoolBurnAmount(uint256 assetRequired_, uint256 assetProportion_)
        internal
        view
        returns (uint256 burnAmount_)
    {
        burnAmount_ = (assetRequired_ - assetProportion_) - (assetProportion_ * dt / ub - assetProportion_);
        burnAmount_ /= precision;
    }

    /**
     * @dev Returns the failed assets and their prices in ascending order
     * @param size_ The size of the array (number of assets failed)
     * @notice returns the array of failed assets and their prices
     */
    function _failedAssetsOrderWithPrice(uint256 size_) internal view returns (address[] memory, uint256[] memory) {
        uint256 count;
        address[] memory _assetsList = new address[](size_);
        uint256[] memory assetsPrice_ = new uint256[](size_);
        uint256 price;
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            if (price <= dt) {
                _assetsList[count] = (assets[i]);
                assetsPrice_[count] = (price);
                count += 1;
            }
        }
        for (uint256 i = 0; i < count - 1; i++) {
            if (assetsPrice_[i] > assetsPrice_[i + 1]) {
                (_assetsList[i], _assetsList[i + 1]) = (_assetsList[i + 1], _assetsList[i]);
                (assetsPrice_[i], assetsPrice_[i + 1]) = (assetsPrice_[i + 1], assetsPrice_[i]);
            }
        }
        if (count > 1 && assetsPrice_[0] > assetsPrice_[1]) {
            (_assetsList[0], _assetsList[1]) = (_assetsList[1], _assetsList[0]);
            (assetsPrice_[0], assetsPrice_[1]) = (assetsPrice_[1], assetsPrice_[0]);
        }
        return (_assetsList, assetsPrice_);
    }

    /**
     * @dev Returns the number of failed assets
     */
    function _noOfFailedAssets() internal view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            if (IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]) < dt) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * @dev Returns the sorted assets and their prices in ascending order
     */
    function _getSortedAssetsWithPrice() internal view returns (address[] memory, uint256[] memory) {
        address[] memory assets_ = new address[](assets.length);
        uint256[] memory assetsPrice_ = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assets_[i] = assets[i];
            assetsPrice_[i] = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
        }

        for (uint256 i = 0; i < assets.length - 1; i++) {
            if (assetsPrice_[i] > assetsPrice_[i + 1]) {
                (assets_[i], assets_[i + 1]) = (assets_[i + 1], assets_[i]);
                (assetsPrice_[i], assetsPrice_[i + 1]) = (assetsPrice_[i + 1], assetsPrice_[i]);
            }
        }

        if (assetsPrice_[0] > assetsPrice_[1]) {
            (assets_[0], assets_[1]) = (assets_[1], assets_[0]);
            (assetsPrice_[0], assetsPrice_[1]) = (assetsPrice_[1], assetsPrice_[0]);
        }
        return (assets_, assetsPrice_);
    }


    /**
     * @dev Burns NSTBL from stake pool
     * @param amount_ The amount of NSTBL to be burned
     */
    function _burnNstblFromStakePool(uint256 amount_) internal {
        burnedFromStakePool += amount_;
        if (amount_ != 0) {
            IStakePool(stakePool).burnNSTBL(amount_);
        }
    }

    /**
     * @dev Requests TBill withdraw from loan manager (only at redemption)
     * @param amount_ The amount of USDC to be withdrawn
     */
    function requestTBillWithdraw(uint256 amount_) internal {
           
        uint256 lUSDCSupply = ILoanManager(loanManager).getLPTotalSupply();
        uint256 lmTokenAmount = ((amount_) / 1e12) * lUSDCSupply / ILoanManager(loanManager).getAssets(lUSDCSupply);

        lmTokenAmount <= lUSDCSupply
            ? ILoanManager(loanManager).requestRedeem(lmTokenAmount)
            : ILoanManager(loanManager).requestRedeem(lUSDCSupply);

    }

    /**
     * @dev Redeems TBill from loan manager
     */
    function _redeemTBill() internal returns (uint256) {
        uint256 balBefore = IERC20Helper(USDC).balanceOf(address(this));
        ILoanManager(loanManager).redeem();
        uint256 balAfter = IERC20Helper(USDC).balanceOf(address(this));
        usdcRedeemed += (balAfter - balBefore);
        IStakePool(stakePool).updatePoolFromHub(true, balAfter - balBefore, 0);
        return (balAfter - balBefore);
    }
}
