pragma solidity 0.8.21;

import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/IERC20Helper.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/IHub.sol";
import "./interfaces/ISPool.sol";
import "@nstbl-stake-pool/contracts/interfaces/IStakePool.sol";

contract NSTBLHubViews {

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

    address public nstblHub;
    address public stakePool;
    address public loanManager;
    address public chainLinkPriceFeed;
    address public nstblToken;
    uint256 public dt;
    uint256 public ub;
    uint256 public lb;
    uint256 public precision = 1e24;
    address[3] public assetFeeds;
    address[3] public assets;


    //testnet goerli addresses
    address public immutable USDC = address(0x94A4DC7C451Db157cd64E017CDF726501432b7e7);
    address public immutable USDT = address(0x6fa19Db493Ca53FB2E6Bc7b7Cee7ecC107DA3753);
    address public immutable DAI = address(0xf864EeC64EcD77E24d46aE841bf6fae855e61514);

    constructor(address nstblHub_, address stakePool_, address loanManager_, address chainLinkPriceFeed_, address nstblToken_, uint256 dt_, uint256 ub_, uint256 lb_) {
        nstblHub = nstblHub_;
        stakePool = stakePool_;
        loanManager = loanManager_;
        chainLinkPriceFeed = chainLinkPriceFeed_;
        nstblToken = nstblToken_;
        dt = dt_;
        ub = ub_;
        lb = lb_;
        assets = [
            address(0x94A4DC7C451Db157cd64E017CDF726501432b7e7),
            address(0x6fa19Db493Ca53FB2E6Bc7b7Cee7ecC107DA3753),
            address(0xf864EeC64EcD77E24d46aE841bf6fae855e61514)
        ];
    }

    function updateAssetFeeds(address[3] memory assetFeeds_) external {
        assetFeeds[0] = assetFeeds_[0];
        assetFeeds[1] = assetFeeds_[1];
        assetFeeds[2] = assetFeeds_[2];
    }

    function getMaxRedeemAmount() public view returns (uint256 redeemAmount_) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        uint256[] memory balances = new uint256[](3);
        balances[0] = ILoanManager(loanManager).getMaturedAssets() + IHub(nstblHub).stablesBalances(USDC) * 1e12;
        balances[1] = IHub(nstblHub).stablesBalances(USDT) * 1e12;
        balances[2] = IHub(nstblHub).stablesBalances(DAI);
        uint256 tvl = balances[0] + balances[1] + balances[2];
        if(p1>dt){
            redeemAmount_ = (IHub(nstblHub).stablesBalances(USDC) * 1e12) * tvl / balances[0];
        }
        else if (p1<dt) { 
            redeemAmount_ = (IHub(nstblHub).stablesBalances(USDC) * 1e12) * tvl * p1 / (balances[0] * dt);
        }
    }

    function getNSTBLPrice() external view returns(uint256 price_) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        
        uint256[] memory balances = new uint256[](3);
        balances[0] = IHub(nstblHub).stablesBalances(USDC) * 1e12;
        balances[1] = IHub(nstblHub).stablesBalances(USDT) * 1e12;
        balances[2] = IHub(nstblHub).stablesBalances(DAI);

        uint256 TVL = balances[0] * p1 + balances[1] * p2 + balances[2] * p3 + ILoanManager(loanManager).getMaturedAssets() * 1e8;
        uint256 tokenSupply = IERC20Helper(nstblToken).totalSupply() + (ILoanManager(loanManager).getMaturedAssets() - ISPool(stakePool).oldMaturityVal());
        price_ = TVL/(tokenSupply);
    }

    function previewUnstake(address user_, uint8 trancheId_) external view returns(uint256 nstblAmt_, address[] memory stables_, uint256[] memory stablesAmounts_) {
        stables_ = new address[](_noOfFailedAssets());
        stablesAmounts_ = new uint256[](_noOfFailedAssets());
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        
        if (p1 > dt && p2 > dt && p3 > dt) {
            nstblAmt_ = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_);
        } else {
            (address[] memory assets_, uint256[] memory assetAmounts_, uint256 unstakeBurnAmount_) = _getUnstakePreviewParams(user_, trancheId_);
            nstblAmt_ = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_) - unstakeBurnAmount_;
            stables_ = assets_;
            stablesAmounts_ = assetAmounts_;
        }
    }

    function previewRedeem(uint256 amount_) external view returns(address[] memory stables_, uint256[] memory stablesAmounts_, uint256[] memory extraStablesAmounts_, uint256 tBillsRedeemed_, uint256 burnAmt_, uint256 spBurnAmt_){
        stables_ = new address[](3);
        stablesAmounts_ = new uint256[](3);
        extraStablesAmounts_ = new uint256[](3);
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        require(amount_ <= getMaxRedeemAmount(), "HUB Views: amount exceeded");
        if(p1 > dt && p2>dt && p3>dt){
            stables_[0] = USDC;
            stables_[1] = USDT;
            stables_[2] = DAI;
            (stablesAmounts_, tBillsRedeemed_) = _previewRedeemNormal(amount_);
        }
        else{
            (stables_, stablesAmounts_, extraStablesAmounts_, tBillsRedeemed_, burnAmt_, spBurnAmt_) = _previewRedeemForNonStaker(amount_);
        }

    }

    function _previewRedeemNormal(uint256 amount_) internal view returns(uint256[] memory amounts_, uint256 tBillsRedeemed_){
        uint256 adjustedDecimals;
        amounts_ = new uint256[](3);
        uint256[] memory balances = new uint256[](3);
        balances[0] = IHub(nstblHub).stablesBalances(USDC) * 1e12 + ILoanManager(loanManager).getMaturedAssets();
        balances[1] = IHub(nstblHub).stablesBalances(USDT) * 1e12;
        balances[2] = IHub(nstblHub).stablesBalances(DAI);
        uint256 tvl = balances[0] + balances[1] + balances[2];
        uint256 redemptionAllocation;

        for (uint256 i = 0; i < assets.length; i++) {
            adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(assets[i]).decimals();
            redemptionAllocation = balances[i] * 1e18 / tvl;
            amounts_[i] = (amount_ * redemptionAllocation) / (1e18 * 10 ** adjustedDecimals)
                <= IHub(nstblHub).stablesBalances(assets[i])
                ? (amount_ * redemptionAllocation) / (1e18 * 10 ** adjustedDecimals)
                : IHub(nstblHub).stablesBalances(assets[i]);
        }
        tBillsRedeemed_ = IHub(nstblHub).tBillPercent() * amount_ / 1e4;
    }


    function _previewRedeemForNonStaker(uint256 amount_) internal view returns(address[] memory stables_, uint256[] memory stablesAmounts_, uint256[] memory extraStablesAmounts_, uint256 tBillsRedeemed_, uint256 burnAmt_, uint256 spBurnAmt_) {

        localVars memory vars;
        uint256 precisionAmount = amount_ * precision;
        uint256[] memory sortedAssetsPrice;
        stables_ = new address[](3);
        stablesAmounts_ = new uint256[](3);
        extraStablesAmounts_ = new uint256[](3);
        (stables_, sortedAssetsPrice) = _getSortedAssetsWithPrice();
        
        uint256[] memory redemptionAlloc = _calculateRedemptionAllocation(stables_);
        for (uint256 i = 0; i < stables_.length; i++) {
            if (sortedAssetsPrice[i] < dt) {
                vars.belowDT = true;
                if (sortedAssetsPrice[i] < lb) {
                    vars.burnFromStakePool = true;
                } else {
                    vars.burnFromStakePool = false;
                }
            } else {
                vars.belowDT = false;
            }

            vars.assetBalance = IHub(nstblHub).stablesBalances(stables_[i]) * precision;
            vars.adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(stables_[i]).decimals();
            if (!vars.belowDT) {
                vars.assetRequired = (redemptionAlloc[i] * precisionAmount / 1e18) + vars.remainingNstbl;
                (vars.remainingNstbl, stablesAmounts_[i]) = _calcNormal(
                    stables_[i], vars.assetRequired, vars.assetBalance, vars.adjustedDecimals
                );
            } else {
                vars.assetProportion =
                    ((redemptionAlloc[i] * precisionAmount / 1e18) + vars.remainingNstbl) / 10 ** vars.adjustedDecimals;
                vars.assetRequired = vars.assetProportion * dt / sortedAssetsPrice[i];
                extraStablesAmounts_[i] = (vars.assetRequired - vars.assetProportion)/precision;
                (vars.remainingNstbl, vars.burnAmount, stablesAmounts_[i]) = _calcBelowDepeg(
                    stables_[i],
                    vars.assetProportion,
                    vars.assetRequired,
                    vars.assetBalance,
                    vars.adjustedDecimals,
                    vars.burnAmount,
                    sortedAssetsPrice[i]
                );
                spBurnAmt_ += vars.burnFromStakePool
                    ? _stakePoolBurnAmount(vars.assetRequired, vars.assetProportion, vars.adjustedDecimals)
                    : 0;
            }
        }
        burnAmt_ += vars.burnAmount;
        tBillsRedeemed_ = amount_ * IHub(nstblHub).tBillPercent() / 1e4;
    }

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

    function _calculateRedemptionAllocation(address[] memory assets_)
        internal
        view
        returns (uint256[] memory allocation_)
    {
        uint256[] memory balances = new uint256[](3);
        allocation_ = new uint256[](3);

        for (uint256 i = 0; i < assets_.length; i++) {
            if (assets_[i] == assets[0]) {
                balances[i] = IHub(nstblHub).stablesBalances(assets_[i]) * 1e12 + ILoanManager(loanManager).getMaturedAssets();
            } else if (assets_[i] == assets[1]) {
                balances[i] = IHub(nstblHub).stablesBalances(assets_[i]) * 1e12;
            } else {
                balances[i] = IHub(nstblHub).stablesBalances(assets_[i]);
            }
        }
        uint256 tvl = balances[0] + balances[1] + balances[2];
        allocation_[0] = balances[0] * 1e18 / tvl;
        allocation_[1] = balances[1] * 1e18 / tvl;
        allocation_[2] = balances[2] * 1e18 / tvl;
    }

    function _calcNormal(
        address asset_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_
    ) internal view returns (uint256 remainingNstbl_, uint256 stableAmounts_) {
        if (assetRequired_ <= assetBalance_ * 10 ** adjustedDecimals_) {
            stableAmounts_ = assetRequired_ / (precision * 10 ** adjustedDecimals_);
            remainingNstbl_ = 0;
        } else {
            stableAmounts_ = assetBalance_ / precision;
            remainingNstbl_ = (assetRequired_ - assetBalance_ * 10 ** adjustedDecimals_);
        }
    }

    function _calcBelowDepeg(
        address asset_,
        uint256 assetProportion_,
        uint256 assetRequired_,
        uint256 assetBalance_,
        uint256 adjustedDecimals_,
        uint256 burnAmount_,
        uint256 assetPrice_
    ) internal view returns (uint256 remainingNstbl_, uint256 burnAmt_, uint256 stableAmounts_) {
        uint256 redeemableNstbl;
        burnAmt_ = burnAmount_;

        if (assetRequired_ <= assetBalance_) {
            stableAmounts_ = assetRequired_ / precision;
            remainingNstbl_ = 0;
            burnAmt_ += (assetRequired_ - assetProportion_) * 10 ** adjustedDecimals_ / precision;
        } else {
            redeemableNstbl = assetBalance_ * assetPrice_ / dt;
            burnAmt_ += (assetBalance_ - redeemableNstbl) * 10 ** adjustedDecimals_ / precision;
            remainingNstbl_ = (assetProportion_ - redeemableNstbl) * 10 ** adjustedDecimals_;
            stableAmounts_ = assetBalance_ / precision;
        }
    }

    function _stakePoolBurnAmount(uint256 assetRequired_, uint256 assetProportion_, uint256 adjustedDecimals_)
        internal
        view
        returns (uint256 burnAmount_)
    {
        burnAmount_ = (assetRequired_ - (assetProportion_ * dt / lb)) * 10 ** adjustedDecimals_;
        burnAmount_ /= precision;
    }
     
    function _getUnstakePreviewParams(address user_, uint8 trancheId_) internal view returns(address[] memory assets_, uint256[] memory assetAmounts_, uint256 unstakeBurnAmount_){
        (address[] memory failedAssets_, uint256[] memory failedAssetsPrice_) =
            _failedAssetsOrderWithPrice(_noOfFailedAssets());
        assets_ = new address[](failedAssets_.length);
        assetAmounts_ = new uint256[](failedAssets_.length);
        (assets_, assetAmounts_, unstakeBurnAmount_,) = _getStakerRedeemParams(user_, trancheId_, failedAssets_, failedAssetsPrice_);
    }

    function _noOfFailedAssets() internal view returns (uint256 count_) {
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            if (IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]) < dt) {
                count_ += 1;
            }
        }
    }

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
            vars.assetBalance = IHub(nstblHub).stablesBalances(failedAssets_[i]) * precision;

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
}