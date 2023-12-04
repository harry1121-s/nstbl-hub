pragma solidity 0.8.21;

contract NSTBLHubAuxiliary {
    // function previewRedeem(uint256 amount_) external view returns(uint256[] memory stablesAmount_) {
    //     stablesAmount_ = new uint256[](3);
    //     (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
    //     if(p1 > dt && p2 > dt && p3 > dt){
    //         stablesAmount_ = _previewRedeemNormal(amount_);
    //     }
    //     else {
    //         stablesAmount_ = _previewRedeemDepeg(amount_);
    //     }
    // }

    // function _previewRedeemNormal(uint256 amount_) internal view returns(uint256[] memory stablesAmount_) {
    //     stablesAmount_ = new uint256[](3);
    //     uint256 adjustedDecimals;

    //     uint256[] memory balances = _getAssetBalances();
    //     uint256 tvl = balances[0] + balances[1] + balances[2];
    //     uint256 redemptionAllocation;

    //     for (uint256 i = 0; i < assets.length; i++) {
    //         adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(assets[i]).decimals();
    //         redemptionAllocation = balances[i]*1e18 / tvl;
    //         stablesAmount_[i] = (amount_ * redemptionAllocation)/(1e18 * 10 ** adjustedDecimals)
    //                 <= stablesBalances[assets[i]]
    //                 ? (amount_ * redemptionAllocation)/(1e18 * 10 ** adjustedDecimals)
    //                 : stablesBalances[assets[i]];
            
    //     }
    // }

    // function _previewRedeemDepeg(uint256 amount_) internal view returns(uint256[] memory stablesAmount_){
    //     stablesAmount_ = new uint256[](3);
    //     localVars memory vars;
    //     uint256 precisionAmount = amount_ * precision;

    //     (address[] memory sortedAssets, uint256[] memory sortedAssetsPrice) = _getSortedAssetsWithPrice();
    //     uint256[] memory redemptionAlloc = _calculateRedemptionAllocation(sortedAssets);
    //     for (uint256 i = 0; i < sortedAssets.length; i++) {
            
    //         if (sortedAssetsPrice[i] <= dt) {
    //             vars.belowDT = true;
    //             if (sortedAssetsPrice[i] <= lb) {
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
    //             // vars.remainingNstbl = _transferNormal(
    //             //     destAddress_, sortedAssets[i], vars.assetRequired, vars.assetBalance, vars.adjustedDecimals
    //             // );
    //         } else {
    //             vars.assetProportion = (
    //                 (redemptionAlloc[i] * precisionAmount / 1e18) + vars.remainingNstbl
    //             ) / 10 ** vars.adjustedDecimals;
    //             vars.assetRequired = vars.assetProportion * dt / sortedAssetsPrice[i];

    //             // (vars.remainingNstbl, vars.burnAmount) = _transferBelowDepeg(
    //             //     destAddress_,
    //             //     sortedAssets[i],
    //             //     vars.assetProportion,
    //             //     vars.assetRequired,
    //             //     vars.assetBalance,
    //             //     vars.adjustedDecimals,
    //             //     vars.burnAmount,
    //             //     sortedAssetsPrice[i]
    //             // );

    //             vars.stakePoolBurnAmount += vars.burnFromStakePool
    //                 ? _stakePoolBurnAmount(vars.assetRequired, vars.assetProportion)
    //                 : 0;
    //             console.log("stake pool burn ", sortedAssets[i], vars.stakePoolBurnAmount);
    //         }
    //     }

    // }

     //returns nstbl token amt, usdc amt, usdt amt, dai amt
    // function previewUnstake(address user_, uint8 trancheId_) external view returns(uint256 nstblAmt_, uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_) {
    //     (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

    //     if (p1 > dt && p2 > dt && p3 > dt) {
    //         nstblAmt_ = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_);
    //         usdcAmt_ = 0;
    //         usdtAmt_ = 0;
    //         daiAmt_ = 0;

    //     } else {
    //         (address[] memory assets_, uint256[] memory assetAmounts_, uint256 unstakeBurnAmount_) = _getUnstakePreviewParams(user_, trancheId_);
    //         nstblAmt_ = IStakePool(stakePool).getUserAvailableTokens(user_, trancheId_) - unstakeBurnAmount_;
    //         for(uint256 i = 0; i < assets_.length; i++){
    //             usdcAmt_ = assets_[i] == assets[0] ? assetAmounts_[i] : 0;
    //             usdtAmt_ = assets_[i] == assets[1] ? assetAmounts_[i] : 0;
    //             daiAmt_ = assets_[i] == assets[2] ? assetAmounts_[i] : 0;
    //         }
    //     }
    // }

    // function _getUnstakePreviewParams(address user_, uint8 trancheId_) internal view returns(address[] memory assets_, uint256[] memory assetAmounts_, uint256 unstakeBurnAmount_){
    //     (address[] memory failedAssets_, uint256[] memory failedAssetsPrice_) =
    //         _failedAssetsOrderWithPrice(_noOfFailedAssets());
    //     assets_ = new address[](failedAssets_.length);
    //     assetAmounts_ = new uint256[](failedAssets_.length);
    //     (assets_, assetAmounts_, unstakeBurnAmount_,) = _getStakerRedeemParams(user_, trancheId_, failedAssets_, failedAssetsPrice_);
    // }

}