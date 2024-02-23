pragma solidity 0.8.21;

import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@nstbl-loan-manager/contracts/upgradeable/VersionedInitializable.sol";
import "./NSTBLHUBStorage.sol";
import { console } from "forge-std/Test.sol";

contract NSTBLHub is INSTBLHub, NSTBLHUBStorage, VersionedInitializable {
    using SafeERC20 for IERC20Helper;

    uint256 private _locked;

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

    struct localVars2 {
        uint256 assetsLeft;
        uint256 redeemableNstbl;
        uint256 assetBalance;
        uint256 assetRequired;
        uint256 targetPrice;
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
    INITIALIZE
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address nstblToken_,
        address stakePool_,
        address chainLinkPriceFeed_,
        address atvl_,
        address loanManager_,
        address aclManager_,
        uint256 eqTh_
    ) external initializer {
        _zeroAddressCheck(nstblToken_);
        _zeroAddressCheck(stakePool_);
        _zeroAddressCheck(chainLinkPriceFeed_);
        _zeroAddressCheck(atvl_);
        _zeroAddressCheck(loanManager_);
        _zeroAddressCheck(aclManager_);
        nstblToken = nstblToken_;
        stakePool = stakePool_;
        chainLinkPriceFeed = chainLinkPriceFeed_;
        atvl = atvl_;
        loanManager = loanManager_;
        aclManager = aclManager_;
        eqTh = eqTh_;
        assets = [
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        ];
        _locked = 1;
        precision = 1e24;
        emit InitializedHub(nstblToken, stakePool, chainLinkPriceFeed, atvl, loanManager, aclManager, eqTh);
    }

    /*//////////////////////////////////////////////////////////////
    EXTERNALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc INSTBLHub
     */
    function deposit(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_, address destAddress_) external authorizedCaller {
        _zeroAddressCheck(destAddress_);
        (uint256 a1_, uint256 a2_, uint256 a3_) = _validateSystemAllocation(usdcAmt_, usdtAmt_, daiAmt_);
        _checkEquilibrium(a1_, a2_, a3_, usdcAmt_, usdtAmt_, daiAmt_);
        uint256 tBillsAmount = _calculateTBillsAmount(usdcAmt_, usdtAmt_, daiAmt_);
        if (tBillsAmount > 0) {
            require(ILoanManager(loanManager).isValidDepositAmount(tBillsAmount), "HUB: Invalid Investment");
        }
        //Deposit required Tokens
        IERC20Helper(USDC).safeTransferFrom(msg.sender, address(this), usdcAmt_);
        stablesBalances[USDC] += (usdcAmt_ - tBillsAmount);
        if (a2_ != 0) {
            IERC20Helper(USDT).safeTransferFrom(msg.sender, address(this), usdtAmt_);
            stablesBalances[USDT] += usdtAmt_;
        }
        if (a3_ != 0) {
            IERC20Helper(DAI).safeTransferFrom(msg.sender, address(this), daiAmt_);
            stablesBalances[DAI] += daiAmt_;
        }
        IStakePool(stakePool).updatePoolFromHub(false, 0, tBillsAmount);
        _investUSDC(tBillsAmount);
        if (IERC20Helper(nstblToken).totalSupply() == 0) {
            IStakePool(stakePool).updateMaturityValue();
        }
        IERC20Helper(nstblToken).mint(destAddress_, (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_);
        emit Deposited(usdcAmt_, usdtAmt_, daiAmt_, tBillsAmount, (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_, msg.sender);
    }

    /**
     * @inheritdoc INSTBLHub
     */
     /**
     function requestRedemption(uint256 amount_) external authorizedCaller nonReentrant {}
        event: amount, tbills requested for redemption
     function processRedemption(address dstAddress_) external authorizedCaller nonReentrant {}
        event: dst address, nstbl redeemed, usdc,usdt,dai amounts
        event: atvl burn amount, sp burn amount, excess USDC,USDT,DAI amounts
     function getRedemptionStatus() external view returns (bool status_) {}
     function previewProcessRedemption(uint256 amount_) external view returns(uint256[] memory assetAmounts_, uint256 tBillsRedeemed_) {}
      */

    function requestRedemption(uint256 amount_) external authorizedCaller nonReentrant {
        require(amount_ > 0 && amount_ <= IERC20Helper(nstblToken).totalSupply(), "HUB: Invalid Redemption Amount");
        IERC20Helper(nstblToken).safeTransferFrom(msg.sender, address(this), amount_);
        nstblDebt += amount_;
        uint256 newTVL = IERC20Helper(nstblToken).totalSupply() - amount_;
        uint256 tBillsRedeemAmount = ILoanManager(loanManager).getMaturedAssets() - (tBillPercent * newTVL / 1e4);
        _requestTBillWithdraw(tBillsRedeemAmount);
        emit RedemptionRequested(amount_, tBillsRedeemAmount);
    }

    function processRedemption(address dstAddress_) external authorizedCaller nonReentrant {
        _zeroAddressCheck(dstAddress_);
        require(ILoanManager(loanManager).awaitingRedemption(), "HUB: No redemption requested");
        _redeemTBill();
        uint256[] memory balances = _getAssetBalances();
        uint256 tvl = balances[0] + balances[1] + balances[2];
        uint256 redeemAmount = _getRedeemableNSTBL(balances, tvl);
        uint256[] memory redemptionRatios = _getRedemptionRatios(balances, tvl);
        uint256 adjustedDecimals;
        uint256 availAssets;
        IERC20Helper(nstblToken).burn(address(this), redeemAmount);
        for (uint256 i = 0; i < assets.length; i++) {
            adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(assets[i]).decimals();
            availAssets = (redeemAmount * redemptionRatios[i]) / (1e18 * 10 ** adjustedDecimals);
            IERC20Helper(assets[i]).safeTransfer(dstAddress_, availAssets);
            stablesBalances[assets[i]] -= availAssets;
        }
        IERC20Helper(nstblToken).safeTransfer(dstAddress_, nstblDebt-redeemAmount);
        nstblDebt = 0;
        // emit RedemptionProcessed(dstAddress_, tokensToRedeem);
    }

    function _getRedeemableNSTBL(uint256[] memory balances_, uint256 tvl_) internal view returns (uint256 redeemAmount_) {
        (uint256 p1,,) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        uint256 maxAmount;
        if(p1>dt){
            maxAmount = (stablesBalances[USDC] * 1e12) * tvl_ / balances_[0];
        }
        else if (p1<dt) { 
            maxAmount = (stablesBalances[USDC] * 1e12) * tvl_ * p1 / (balances_[0] * dt);
        }
        redeemAmount_ = nstblDebt > maxAmount ? maxAmount : nstblDebt;
    }

    function _getRedemptionRatios(uint256[] memory balances_, uint256 tvl_) internal pure returns(uint256[] memory ratios_){
        ratios_ = new uint256[](3);
        ratios_[0] = balances_[0] * 1e18 / tvl_;
        ratios_[1] = balances_[1] * 1e18 / tvl_;
        ratios_[2] = balances_[2] * 1e18 / tvl_;
    }

    

    // function redeem(uint256 amount_, address destAddress_) external authorizedCaller nonReentrant {
    //     _zeroAddressCheck(destAddress_);
    //     (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
    //     if (p1 > dt && p2 > dt && p3 > dt) {
    //         _redeemNormal(amount_, destAddress_);
    //     } else {
    //         _redeemForNonStaker(amount_, destAddress_);
    //     }
    // }

    /**
     * @inheritdoc INSTBLHub
     */
    function stake(address user_, uint256 amount_, uint8 trancheId_) external authorizedCaller nonReentrant {
        _zeroAddressCheck(user_);
        require(
            amount_ + IERC20Helper(nstblToken).balanceOf(stakePool) <= 40 * IERC20Helper(nstblToken).totalSupply() / 100,
            "HUB: STAKE_LIMIT_EXCEEDED"
        );
        IERC20Helper(nstblToken).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20Helper(nstblToken).safeIncreaseAllowance(stakePool, amount_);
        IStakePool(stakePool).stake(user_, amount_, trancheId_);
    }

    /**
     * @inheritdoc INSTBLHub
     */
    function unstake(address user_, uint8 trancheId_, address destAddress_) external authorizedCaller nonReentrant {
        _zeroAddressCheck(user_);
        _zeroAddressCheck(destAddress_);
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        if (p1 > dt && p2 > dt && p3 > dt) {
            _unstakeNstbl(user_, trancheId_, false, destAddress_);
        } else {
            _unstakeAndRedeemNstbl(user_, trancheId_, destAddress_);
        }
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN ONLY
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc INSTBLHub
     */
    function updateAssetFeeds(address[3] memory assetFeeds_) external onlyAdmin {
        _zeroAddressCheck(assetFeeds_[0]);
        _zeroAddressCheck(assetFeeds_[1]);
        _zeroAddressCheck(assetFeeds_[2]);
        assetFeeds[0] = assetFeeds_[0];
        assetFeeds[1] = assetFeeds_[1];
        assetFeeds[2] = assetFeeds_[2];
    }

    /**
     * @inheritdoc INSTBLHub
     */
    function setSystemParams(uint256 dt_, uint256 ub_, uint256 lb_, uint256 tBillPercent_, uint256 eqTh_)
        external
        onlyAdmin
    {
        require(tBillPercent_ >= 7e3, "HUB: Invalid T-Bill Percent");
        require(eqTh_ <= 5e22, "HUB: Invalid Equilibrium Threshold");
        dt = dt_;
        ub = ub_;
        lb = lb_;
        tBillPercent = tBillPercent_;
        eqTh = eqTh_;
    }

    /**
     * @inheritdoc INSTBLHub
     */
    function processTBillWithdraw() external authorizedCaller returns (uint256 usdcReceived_) {
        require(ILoanManager(loanManager).awaitingRedemption(), "HUB: No redemption requested");
        usdcReceived_ = _redeemTBill();
    }

    /*//////////////////////////////////////////////////////////////
    VIEWS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc INSTBLHub
     */
    function previewDeposit(uint256 depositAmount_)
        external
        view
        returns (uint256 amt1_, uint256 amt2_, uint256 amt3_, uint256 tBillAmt_)
    {
        (uint256 a1_, uint256 a2_, uint256 a3_) = _getSystemAllocation();
        uint256 tAlloc = a1_ + a2_ + a3_;
        amt1_ = a1_ * depositAmount_ * 10 ** IERC20Helper(USDC).decimals() / tAlloc;
        amt2_ = a2_ * depositAmount_ * 10 ** IERC20Helper(USDT).decimals() / tAlloc;
        amt3_ = a3_ * depositAmount_ * 10 ** IERC20Helper(DAI).decimals() / tAlloc;
        tBillAmt_ = _calculateTBillsAmount(amt1_, amt2_, amt3_);
        if (tBillAmt_ > 0) {
            require(ILoanManager(loanManager).isValidDepositAmount(tBillAmt_), "HUB: Invalid Investment Amount");
        }
    }

    /**
     * @inheritdoc INSTBLHub
     */
    function validateDepositEquilibrium(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_)
        external
        view
        returns (bool result_)
    {
        (uint256 a1_, uint256 a2_, uint256 a3_) = _validateSystemAllocation(usdcAmt_, usdtAmt_, daiAmt_);
        (uint256 oldEq, uint256 newEq) = _calculateEquilibrium(a1_, a2_, a3_, usdcAmt_, usdtAmt_, daiAmt_);
        if (oldEq == 0) {
            if (newEq < eqTh) {
                result_ = true;
            }
        } else {
            if (newEq <= oldEq || newEq < eqTh) {
                result_ = true;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
    INTERNALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the amount of usdc required to be deposited in T-bills
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @return tBillsAmount_ the amount of usdc required to be deposited in T-bills
     */
    function _calculateTBillsAmount(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_)
        internal
        view
        returns (uint256 tBillsAmount_)
    {
        uint256 tBillAssets = ILoanManager(loanManager).getMaturedAssets();
        uint256 targetSupply = (stablesBalances[USDC] + stablesBalances[USDT]) * 1e12 + stablesBalances[DAI]
            + tBillAssets + (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_;
        uint256 tBillsRequired = tBillPercent * targetSupply / 1e4;
        tBillsAmount_ = tBillsRequired > tBillAssets ? (tBillsRequired - tBillAssets) : 0; //case when there are already sufficient stables deposited in TBills
        tBillsAmount_ = (usdcAmt_ * 1e12) > tBillsAmount_ ? tBillsAmount_ / 1e12 : usdcAmt_; //hypothetical case when usdc deposit amount is extermely small
    }

    /**
     * @dev Validates the system allocation according to the system state
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @return a1_ the system allocations for USDC
     * @return a2_ the system allocations for USDT
     * @return a3_ the system allocations for DAI
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
     * @return a1_ the system allocations for USDC
     * @return a2_ the system allocations for USDT
     * @return a3_ the system allocations for DAI
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
        (uint256 oldEq, uint256 newEq) = _calculateEquilibrium(a1_, a2_, a3_, usdcAmt_, usdtAmt_, daiAmt_);
        if (oldEq == 0) {
            require(newEq < eqTh, "HUB::Deposit Not Allowed");
        } else {
            require(newEq <= oldEq || newEq < eqTh, "HUB::Deposit Not Allowed");
        }
    }

    /**
     * @dev Calculates the old and new system equilibrium
     * @param a1_ The system allocation for USDC
     * @param a2_ The system allocation for USDT
     * @param a3_ The system allocation for DAI
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @return oldEq_ system equilibrium value before deposit action
     * @return newEq_ system equilibrium value after deposit action
     */
    function _calculateEquilibrium(
        uint256 a1_,
        uint256 a2_,
        uint256 a3_,
        uint256 usdcAmt_,
        uint256 usdtAmt_,
        uint256 daiAmt_
    ) internal view returns (uint256 oldEq_, uint256 newEq_) {
        uint256 tAlloc = a1_ + a2_ + a3_;
        uint256[] memory balances = _getAssetBalances();
        uint256 tvlOld = balances[0] + balances[1] + balances[2];
        uint256 tvlNew = tvlOld + (usdcAmt_ + usdtAmt_) * 1e12 + daiAmt_;

        uint256[] memory cr = new uint256[](3);
        if (tvlOld > 0) {
            cr[0] = a1_ != 0 ? (balances[0] * tAlloc * precision) / (a1_ * tvlOld) : 0;
            cr[1] = a2_ != 0 ? (balances[1] * tAlloc * precision) / (a2_ * tvlOld) : 0;
            cr[2] = a3_ != 0 ? (balances[2] * tAlloc * precision) / (a3_ * tvlOld) : 0;
            oldEq_ = _calcEq(cr[0], cr[1], cr[2]);
        } else {
            oldEq_ = 0;
        }

        cr[0] = a1_ != 0 ? ((balances[0] + usdcAmt_ * 1e12) * tAlloc * precision) / (a1_ * tvlNew) : 0;
        cr[1] = a2_ != 0 ? ((balances[1] + usdtAmt_ * 1e12) * tAlloc * precision) / (a2_ * tvlNew) : 0;
        cr[2] = a3_ != 0 ? ((balances[2] + daiAmt_) * tAlloc * precision) / (a3_ * tvlNew) : 0;

        newEq_ = _calcEq(cr[0], cr[1], cr[2]);
    }

    /**
     * @dev Calculates the equilibrium value according to the coverage ratio of each asset
     * @param cr1_ The coverage ratio of USDC
     * @param cr2_ The coverage ratio of USDT
     * @param cr3_ The coverage ratio of DAI
     * @return eq_ the calculated equilibrium value
     */
    function _calcEq(uint256 cr1_, uint256 cr2_, uint256 cr3_) internal view returns (uint256 eq_) {
        eq_ = (_modSub(cr1_) + _modSub(cr2_) + _modSub(cr3_)) / 3;
    }

    /**
     * @dev Calculates modulus subtraction with precision value
     * @param a_ input value to perform modulus subtraction
     * @return result_ the calculated modulus subtraction value
     */
    function _modSub(uint256 a_) internal view returns (uint256 result_) {
        if (a_ != 0) {
            result_ = a_ > precision ? a_ - precision : precision - a_;
        } else {
            result_ = 0;
        }
    }

    /**
     * @dev Returns the balances for system assets
     * @return balances_ array containing balances of USDC, USDT, DAI
     */
    function _getAssetBalances() internal view returns (uint256[] memory balances_) {
        balances_ = new uint256[](3);
        balances_[0] = ILoanManager(loanManager).getMaturedAssets() + stablesBalances[USDC] * 1e12;
        balances_[1] = stablesBalances[USDT] * 1e12;
        balances_[2] = stablesBalances[DAI];
    }

    /**
     * @dev Invests USDC in the loan manager
     * @param amt_ The amount of USDC to be invested
     */
    function _investUSDC(uint256 amt_) internal {
        if (amt_ > 0) {
            usdcInvested += amt_;
            IERC20Helper(USDC).safeIncreaseAllowance(loanManager, amt_);
            ILoanManager(loanManager).deposit(amt_);
        }
    }

    // /**
    //  * @dev Redeems NSTBL for a non-staker in non-depeg scenario
    //  * @param amount_ The amount of NSTBL to be redeemed
    //  */
    // function _redeemNormal(uint256 amount_, address destAddress_) internal {
    //     uint256 availAssets;
    //     uint256 adjustedDecimals;
    //     IERC20Helper(nstblToken).burn(msg.sender, amount_);

    //     uint256[] memory balances = _getAssetBalances();
    //     uint256 tvl = balances[0] + balances[1] + balances[2];
    //     uint256 redemptionAllocation;

    //     for (uint256 i = 0; i < assets.length; i++) {
    //         adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(assets[i]).decimals();
    //         redemptionAllocation = balances[i] * 1e18 / tvl;
    //         availAssets = (amount_ * redemptionAllocation) / (1e18 * 10 ** adjustedDecimals)
    //             <= stablesBalances[assets[i]]
    //             ? (amount_ * redemptionAllocation) / (1e18 * 10 ** adjustedDecimals)
    //             : stablesBalances[assets[i]];
    //         IERC20Helper(assets[i]).safeTransfer(destAddress_, availAssets);
    //         stablesBalances[assets[i]] -= availAssets;
    //     }
    //     _requestTBillWithdraw(tBillPercent * amount_ / 1e4);
    //     emit RedeemedNormal(amount_, destAddress_);
    // }

    /**
     * @dev Unstakes NSTBL for staker in non-depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param depeg_ The depeg status of the system
     * @param destAddress_ receiver address
     */
    function _unstakeNstbl(address user_, uint8 trancheId_, bool depeg_, address destAddress_) internal {
        uint256 tokensUnstaked = IStakePool(stakePool).unstake(user_, trancheId_, depeg_, destAddress_);
    }

    /**
     * @dev Unstakes and redeems NSTBL for staker in depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param destAddress_ receiver address
     * @notice The NSTBL amount is redeemed till it covers the failing stablecoins, then the remaining NSTBL is unstaked and transferred to staker
     */
    function _unstakeAndRedeemNstbl(address user_, uint8 trancheId_, address destAddress_) internal {
        (address[] memory failedAssets_, uint256[] memory failedAssetsPrice_) =
            _failedAssetsOrderWithPrice(_noOfFailedAssets());
        (address[] memory assets_, uint256[] memory _assetAmounts, uint256 unstakeBurnAmount_, uint256 burnAmount_) =
            _getStakerRedeemParams(user_, trancheId_, failedAssets_, failedAssetsPrice_);
        _unstakeAndBurnNstbl(user_, trancheId_, unstakeBurnAmount_, destAddress_);
        _burnNstblFromAtvl(burnAmount_);
        for (uint256 i = 0; i < assets_.length; i++) {
            if (assets_[i] != address(0)) {
                IERC20Helper(assets_[i]).safeTransfer(destAddress_, _assetAmounts[i]);
                stablesBalances[assets_[i]] -= _assetAmounts[i];
            }
        }
        emit UnstakedAndRedeemed(destAddress_, unstakeBurnAmount_, burnAmount_);
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
    )
        internal
        view
        returns (
            address[] memory assets_,
            uint256[] memory assetAmount_,
            uint256 unstakeBurnAmount_,
            uint256 burnAmount_
        )
    {
        assets_ = new address[](failedAssets_.length);
        assetAmount_ = new uint256[](failedAssets_.length);
        localVars2 memory vars;
        vars.assetsLeft = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_) * precision;
        for (uint256 i = 0; i < failedAssets_.length; i++) {
            if (failedAssetsPrice_[i] > ub) {
                vars.targetPrice = dt;
            } else {
                vars.targetPrice = failedAssetsPrice_[i] + 4e6;
            }

            assets_[i] = failedAssets_[i];
            vars.adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(failedAssets_[i]).decimals();
            vars.assetRequired =
                vars.assetsLeft * vars.targetPrice / (failedAssetsPrice_[i] * 10 ** vars.adjustedDecimals);
            vars.assetBalance = stablesBalances[failedAssets_[i]] * precision;

            if (vars.assetRequired <= vars.assetBalance) {
                assetAmount_[i] = vars.assetRequired / precision;
                unstakeBurnAmount_ += (vars.assetsLeft / precision);

                burnAmount_ += ((vars.assetRequired * 10 ** vars.adjustedDecimals - vars.assetsLeft) / precision);
                vars.assetsLeft -= vars.assetsLeft;
                break;
            } else {
                vars.redeemableNstbl =
                    vars.assetBalance * 10 ** vars.adjustedDecimals * failedAssetsPrice_[i] / vars.targetPrice;

                assetAmount_[i] = vars.assetBalance / precision;
                unstakeBurnAmount_ += vars.redeemableNstbl / precision;
                burnAmount_ += ((vars.assetBalance * 10 ** vars.adjustedDecimals) - vars.redeemableNstbl) / precision;
                vars.assetsLeft -= vars.redeemableNstbl;
            }
        }

        return (assets_, assetAmount_, unstakeBurnAmount_, burnAmount_);
    }

    /**
     * @dev Unstakes and burn NSTBL for stakers in depeg scenario
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param unstakeBurnAmount_ The amount of NSTBL to be burned
     * @param destAddress_ receiver address
     * @notice Unstaked the user's NSTBL and burns the required amount of NSTBL
     */
    function _unstakeAndBurnNstbl(address user_, uint8 trancheId_, uint256 unstakeBurnAmount_, address destAddress_)
        internal
    {
        uint256 unstakedTokens = IStakePool(stakePool).unstake(user_, trancheId_, true, address(this));
        IERC20Helper(nstblToken).burn(address(this), unstakeBurnAmount_);
        IERC20Helper(nstblToken).safeTransfer(destAddress_, unstakedTokens - unstakeBurnAmount_);
    }

    /**
     * @dev Burns NSTBL from ATVL
     * @param burnAmount_ The amount of NSTBL to be burned
     */
    function _burnNstblFromAtvl(uint256 burnAmount_) internal {
        atvlBurnAmount += burnAmount_;
        IATVL(atvl).burnNstbl(burnAmount_);
    }

    // /**
    //  * @dev Redeems NSTBL for non-stakers in depeg scenario
    //  * @param amount_ The amount of NSTBL to be redeemed
    //  * @param destAddress_ The address of the user
    //  */
    // function _redeemForNonStaker(uint256 amount_, address destAddress_) internal {
    //     localVars memory vars;
    //     uint256 precisionAmount = amount_ * precision;
    //     IERC20Helper(nstblToken).burn(msg.sender, amount_);
    //     (address[] memory sortedAssets, uint256[] memory sortedAssetsPrice) = _getSortedAssetsWithPrice();
    //     uint256[] memory redemptionAlloc = _calculateRedemptionAllocation(sortedAssets);
    //     for (uint256 i = 0; i < sortedAssets.length; i++) {
    //         if (sortedAssetsPrice[i] < dt) {
    //             vars.belowDT = true;
    //             if (sortedAssetsPrice[i] < lb) {
    //                 vars.burnFromStakePool = true;
    //             } else {
    //                 vars.burnFromStakePool = false;
    //             }
    //         } else {
    //             vars.belowDT = false;
    //         }

    //         vars.assetBalance = stablesBalances[sortedAssets[i]] * precision;
    //         vars.adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(sortedAssets[i]).decimals();
    //         if (!vars.belowDT) {
    //             vars.assetRequired = (redemptionAlloc[i] * precisionAmount / 1e18) + vars.remainingNstbl;
    //             vars.remainingNstbl = _transferNormal(
    //                 destAddress_, sortedAssets[i], vars.assetRequired, vars.assetBalance, vars.adjustedDecimals
    //             );
    //         } else {
    //             vars.assetProportion =
    //                 ((redemptionAlloc[i] * precisionAmount / 1e18) + vars.remainingNstbl) / 10 ** vars.adjustedDecimals;
    //             vars.assetRequired = vars.assetProportion * dt / sortedAssetsPrice[i];
    //             (vars.remainingNstbl, vars.burnAmount) = _transferBelowDepeg(
    //                 destAddress_,
    //                 sortedAssets[i],
    //                 vars.assetProportion,
    //                 vars.assetRequired,
    //                 vars.assetBalance,
    //                 vars.adjustedDecimals,
    //                 vars.burnAmount,
    //                 sortedAssetsPrice[i]
    //             );
    //             vars.stakePoolBurnAmount += vars.burnFromStakePool
    //                 ? _stakePoolBurnAmount(vars.assetRequired, vars.assetProportion, vars.adjustedDecimals)
    //                 : 0;
    //         }
    //     }
    //     _burnNstblFromAtvl((vars.burnAmount - vars.stakePoolBurnAmount));
    //     _burnNstblFromStakePool(vars.stakePoolBurnAmount);
    //     _requestTBillWithdraw(amount_ * tBillPercent / 1e4);
    //     emit RedeemedDepeg(
    //         amount_, destAddress_, (vars.burnAmount - vars.stakePoolBurnAmount), vars.stakePoolBurnAmount
    //     );
    // }

    /**
     * @dev Caulculates the redemption allocation for system assets
     * @param assets_ array containing addresses of system assets in sorted order based on price
     * @return allocation_ array containing allocations of USDC, USDT, DAI for redemption
     */
    function _calculateRedemptionAllocation(address[] memory assets_)
        internal
        view
        returns (uint256[] memory allocation_)
    {
        uint256[] memory balances = new uint256[](3);
        allocation_ = new uint256[](3);

        for (uint256 i = 0; i < assets_.length; i++) {
            if (assets_[i] == assets[0]) {
                balances[i] = stablesBalances[assets_[i]] * 1e12 + ILoanManager(loanManager).getMaturedAssets();
            } else if (assets_[i] == assets[1]) {
                balances[i] = stablesBalances[assets_[i]] * 1e12;
            } else {
                balances[i] = stablesBalances[assets_[i]];
            }
        }
        uint256 tvl = balances[0] + balances[1] + balances[2];
        allocation_[0] = balances[0] * 1e18 / tvl;
        allocation_[1] = balances[1] * 1e18 / tvl;
        allocation_[2] = balances[2] * 1e18 / tvl;
    }

    /**
     * @dev transfers assets to non-stakers if the asset is above depeg threshold
     * @param destAddress_ The address of the receiver
     * @param asset_ The address of the asset
     * @param assetRequired_ The amount of asset required
     * @param assetBalance_ The balance of the asset
     * @param adjustedDecimals_ The adjusted decimals of the asset
     * @return remainingNstbl_ NSTBL tokens not redeemed
     */
    function _transferNormal(
        address destAddress_,
        address asset_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_
    ) internal returns (uint256 remainingNstbl_) {
        if (assetRequired_ <= assetBalance_ * 10 ** adjustedDecimals_) {
            IERC20Helper(asset_).safeTransfer(destAddress_, assetRequired_ / (precision * 10 ** adjustedDecimals_));
            stablesBalances[asset_] -= (assetRequired_ / (precision * 10 ** adjustedDecimals_));
            remainingNstbl_ = 0;
        } else {
            IERC20Helper(asset_).safeTransfer(destAddress_, assetBalance_ / precision);
            stablesBalances[asset_] -= (assetBalance_ / precision);
            remainingNstbl_ = (assetRequired_ - assetBalance_ * 10 ** adjustedDecimals_);
        }
    }

    /**
     * @dev transfers assets to non-stakers if the asset is below depeg threshold
     * @param destAddress_ The address of the receiver
     * @param asset_ The address of the asset
     * @param assetProportion_ The proportion of asset required
     * @param assetRequired_ The amount of asset required
     * @param assetBalance_ The balance of the asset
     * @param adjustedDecimals_ The adjusted decimals of the asset
     * @param burnAmount_ The amount of NSTBL to be burned
     * @param assetPrice_ The price of the asset
     * @return remainingNstbl_ NSTBL tokens not redeemed
     * @return burnAmt_ NSTBL tokens to be burnt
     */
    function _transferBelowDepeg(
        address destAddress_,
        address asset_,
        uint256 assetProportion_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_,
        uint256 burnAmount_,
        uint256 assetPrice_
    ) internal returns (uint256 remainingNstbl_, uint256 burnAmt_) {
        uint256 redeemableNstbl;
        burnAmt_ = burnAmount_;

        if (assetRequired_ <= assetBalance_) {
            IERC20Helper(asset_).safeTransfer(destAddress_, assetRequired_ / precision);
            stablesBalances[asset_] -= (assetRequired_ / precision);

            remainingNstbl_ = 0;
            burnAmt_ += (assetRequired_ - assetProportion_) * 10 ** adjustedDecimals_ / precision;
        } else {
            redeemableNstbl = assetBalance_ * assetPrice_ / dt;
            burnAmt_ += (assetBalance_ - redeemableNstbl) * 10 ** adjustedDecimals_ / precision;
            remainingNstbl_ = (assetProportion_ - redeemableNstbl) * 10 ** adjustedDecimals_;
            IERC20Helper(asset_).safeTransfer(destAddress_, assetBalance_ / precision);
            stablesBalances[asset_] -= (assetBalance_ / precision);
        }
    }

    /**
     * @dev Calculates the amount of NSTBL to be burned from stake pool in case asset is below lowerBound
     * @param assetRequired_ The amount of asset required
     * @param assetProportion_ The proportion of asset required
     * @param adjustedDecimals_ The adjusted decimals of the asset
     * @return burnAmount_ NSTBL tokens to be burnt from stake pool
     */
    function _stakePoolBurnAmount(uint256 assetRequired_, uint256 assetProportion_, uint256 adjustedDecimals_)
        internal
        view
        returns (uint256 burnAmount_)
    {
        burnAmount_ = (assetRequired_ - (assetProportion_ * dt / lb)) * 10 ** adjustedDecimals_;
        burnAmount_ /= precision;
    }

    /**
     * @dev Returns the failed assets and their prices in ascending order
     * @param size_ The size of the array (number of assets failed)
     * @return assetsList_ the array of failed assets
     * @return assetsPrice_ corresponding prices of failed assets
     */
    function _failedAssetsOrderWithPrice(uint256 size_)
        internal
        view
        returns (address[] memory assetsList_, uint256[] memory assetsPrice_)
    {
        uint256 count;
        assetsList_ = new address[](size_);
        assetsPrice_ = new uint256[](size_);
        uint256 price;
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            if (price < dt) {
                assetsList_[count] = (assets[i]);
                assetsPrice_[count] = (price);
                count += 1;
            }
        }
        for (uint256 i = 0; i < count - 1; i++) {
            if (assetsPrice_[i] > assetsPrice_[i + 1]) {
                (assetsList_[i], assetsList_[i + 1]) = (assetsList_[i + 1], assetsList_[i]);
                (assetsPrice_[i], assetsPrice_[i + 1]) = (assetsPrice_[i + 1], assetsPrice_[i]);
            }
        }

        if (count > 1 && assetsPrice_[0] > assetsPrice_[1]) {
            (assetsList_[0], assetsList_[1]) = (assetsList_[1], assetsList_[0]);
            (assetsPrice_[0], assetsPrice_[1]) = (assetsPrice_[1], assetsPrice_[0]);
        }
    }

    /**
     * @dev Returns the number of failed assets
     */
    function _noOfFailedAssets() internal view returns (uint256 count_) {
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            if (IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]) < dt) {
                count_ += 1;
            }
        }
    }

    /**
     * @dev Returns the sorted assets and their prices in ascending order
     * @return assets_ array containing asset addresses
     * @return assetsPrice_ array containing asset prices
     */
    function _getSortedAssetsWithPrice()
        internal
        view
        returns (address[] memory assets_, uint256[] memory assetsPrice_)
    {
        assets_ = new address[](assets.length);
        assetsPrice_ = new uint256[](assets.length);
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
    function _requestTBillWithdraw(uint256 amount_) internal {
        require(!ILoanManager(loanManager).awaitingRedemption(), "HUB: Redemption already requested");
        uint256 lUSDCSupply = ILoanManager(loanManager).getLPTotalSupply();
        uint256 lmTokenAmount = ((amount_) / 1e12) * lUSDCSupply / ILoanManager(loanManager).getAssets(lUSDCSupply);

        lmTokenAmount <= lUSDCSupply
            ? ILoanManager(loanManager).requestRedeem(lmTokenAmount)
            : ILoanManager(loanManager).requestRedeem(lUSDCSupply);
    }

    /**
     * @dev Redeems TBill from loan manager
     * @return usdcReceived_ amount of USDC received from loan-manager after redemption
     */
    function _redeemTBill() internal returns (uint256 usdcReceived_) {
        uint256 balBefore = IERC20Helper(USDC).balanceOf(address(this));
        ILoanManager(loanManager).redeem();
        uint256 balAfter = IERC20Helper(USDC).balanceOf(address(this));
        stablesBalances[USDC] += (balAfter - balBefore);
        IStakePool(stakePool).updatePoolFromHub(true, balAfter - balBefore, 0);
        usdcReceived_ = (balAfter - balBefore);
    }

    /**
     * @dev Get the implementation contract version
     * @return revision_ The implementation contract version
     */
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = REVISION;
    }

    /**
     * @dev Get the implementation contract version
     * @return version_ The implementation contract version
     */
    function getVersion() public pure returns (uint256 version_) {
        version_ = getRevision();
    }

    /**
     * @dev Checks if an input address is zero or not
     * @param address_ address to verify
     */
    function _zeroAddressCheck(address address_) internal pure {
        require(address_ != address(0), "HUB: INVALID_ADDRESS");
    }
}
