pragma solidity 0.8.21;

import {IACLManager} from "@nstbl-acl-manager/contracts/IACLManager.sol";
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

    constructor(
        address _nstblToken,
        address _stakePool,
        address _chainLinkPriceFeed,
        address _atvl,
        address _loanManager,
        address _aclManager,
        uint256 _eqTh
    ) {
        nstblToken = _nstblToken;
        stakePool = _stakePool;
        chainLinkPriceFeed = _chainLinkPriceFeed;
        atvl = _atvl;
        loanManager = _loanManager;
        aclManager = _aclManager;
        eqTh = _eqTh;
    }

    ///////////////////////////     DEPOSIT Functions ////////////////////////
    function previewDeposit(uint256 _depositAmount)
        external
        view
        returns (uint256 _amt1, uint256 _amt2, uint256 _amt3, uint256 _tBillAmt)
    {
        (uint256 _a1, uint256 _a2, uint256 _a3) = _getSystemAllocation();
        uint256 tAlloc = _a1 + _a2 + _a3;
        _amt1 = _a1 * _depositAmount * 10 ** IERC20Helper(USDC).decimals() / tAlloc;
        _amt2 = _a2 * _depositAmount * 10 ** IERC20Helper(USDT).decimals() / tAlloc;
        _amt3 = _a3 * _depositAmount * 10 ** IERC20Helper(DAI).decimals() / tAlloc;
        _tBillAmt = 7e3 * _amt1 / _a1;
    }

    function deposit(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt) external authorizedCaller {

        (uint256 _a1, uint256 _a2, uint256 _a3) = _validateSystemAllocation(_usdcAmt, _usdtAmt, _daiAmt);
        _checkEquilibrium(_a1, _a2, _a3, _usdcAmt, _usdtAmt, _daiAmt);

        //Deposit required Tokens
        IERC20Helper(USDC).safeTransferFrom(msg.sender, address(this), _usdcAmt);
        usdcDeposited += _usdcAmt;
        if (_a2 != 0) {
            IERC20Helper(USDT).safeTransferFrom(msg.sender, address(this), _usdtAmt);
            usdtDeposited += _usdtAmt;
        }
        if (_a3 != 0) {
            IERC20Helper(DAI).safeTransferFrom(msg.sender, address(this), _daiAmt);
            daiDeposited += _daiAmt;
        }
        IStakePool(stakePool).updatePoolFromHub(false, 0, 7e3 * _usdcAmt / _a1);
        _investUSDC(7e3 * _usdcAmt / _a1);
        if(IERC20Helper(nstblToken).totalSupply() == 0)
        { 
            IStakePool(stakePool).updateMaturityValue();
        }
        IERC20Helper(nstblToken).mint(msg.sender, (_usdcAmt + _usdtAmt) * 1e12 + _daiAmt);
    }

    function _validateSystemAllocation(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt)
        internal
        view
        returns (uint256 _a1, uint256 _a2, uint256 _a3)
    {
        (_a1, _a2, _a3) = _getSystemAllocation();
        require(_a2 == 0 ? _usdtAmt == 0 : true, "HUB: Invalid Deposit"); //add this edge case
        require(_a3 == 0 ? _daiAmt == 0 : true, "HUB: Invalid Deposit");
        require(_usdcAmt + _usdtAmt + _daiAmt != 0, "HUB: Invalid Deposit");
    }

    function _getSystemAllocation() internal view returns (uint256 _a1, uint256 _a2, uint256 _a3) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        require(p1 > dt, "HUB: Invalid Deposit");

        if (p2 > dt && p3 > dt) {
            _a1 = 8e3;
            _a2 = 1e3;
            _a3 = 1e3;
        } else if (p2 > dt && p3 <= dt) {
            _a1 = 85e2;
            _a2 = 15e2;
            _a3 = 0;
        } else if (p2 <= dt && p3 > dt) {
            _a1 = 85e2;
            _a2 = 0;
            _a3 = 15e2;
        } else {
            _a1 = 10e3;
            _a2 = 0;
            _a3 = 0;
        }
    }

    function _checkEquilibrium(
        uint256 _a1,
        uint256 _a2,
        uint256 _a3,
        uint256 _usdcAmt,
        uint256 _usdtAmt,
        uint256 _daiAmt
    ) internal view {
        uint256 tAlloc = _a1 + _a2 + _a3;
        uint256[] memory balances = _getAssetBalances();
        uint256 tvlOld = balances[0] + balances[1] + balances[2];
        uint256 tvlNew = tvlOld + (_usdcAmt + _usdtAmt) * 1e12 + _daiAmt;

        uint256[] memory cr = new uint256[](3);
        uint256 oldEq;
        if (tvlOld != 0) {
            cr[0] = _a1 != 0 ? (balances[0] * 1e12 * tAlloc * precision) / (_a1 * tvlOld) : 0;
            cr[1] = _a2 != 0 ? (balances[1] * 1e12 * tAlloc * precision) / (_a2 * tvlOld) : 0;
            cr[2] = _a3 != 0 ? (balances[2] * tAlloc * precision) / (_a3 * tvlOld) : 0;
            oldEq = _calcEq(cr[0], cr[1], cr[2]);
        }

        cr[0] = _a1 != 0 ? ((balances[0] + _usdcAmt) * 1e12 * tAlloc * precision) / (_a1 * tvlNew) : 0;
        cr[1] = _a2 != 0 ? ((balances[1] + _usdtAmt) * 1e12 * tAlloc * precision) / (_a2 * tvlNew) : 0;
        cr[2] = _a3 != 0 ? ((balances[2] + _daiAmt) * tAlloc * precision) / (_a3 * tvlNew) : 0;

        uint256 newEq = _calcEq(cr[0], cr[1], cr[2]);

        if (oldEq == 0) {
            require(newEq < eqTh, "HUB::Deposit Not Allowed");
        } else {
            require(newEq <= oldEq || newEq < eqTh, "HUB::Deposit Not Allowed");
        }
    }

    function _calcEq(uint256 cr1, uint256 cr2, uint256 cr3) internal view returns (uint256 _eq) {
        _eq = (_modSub(cr1) + _modSub(cr2) + _modSub(cr3)) / 3;
    }

    function _modSub(uint256 _a) internal view returns (uint256) {
        if (_a != 0) {
            return _a > precision ? _a - precision : precision - _a;
        } else {
            return 0;
        }
    }

    function _getAssetBalances() internal view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ILoanManager(loanManager).getMaturedAssets() + usdcDeposited * 1e12;
        balances[1] = usdtDeposited * 1e12;
        balances[2] = daiDeposited;

        return balances;
    }

    function _investUSDC(uint256 _amt) internal {
        //@TODO: integration with stakePool
        usdcInvested += _amt;
        IERC20Helper(USDC).safeIncreaseAllowance(loanManager, _amt);
        ILoanManager(loanManager).deposit(_amt);
    }
    ///////////////////////////     redeem Function ////////////////////////
    function redeem(uint256 _amount, address _user) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(); //usdc
        if (p1 > dt && p2 > dt && p3 > dt) {
            redeemNormal(_amount, _user);
        } else {
            redeemForNonStaker(_amount, _user);
        }
    }

    function unstake(address _user, uint8 _trancheId, address _lpOwner) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        if (p1 > dt && p2 > dt && p3 > dt) {
            unstakeNstbl(_user, _trancheId, false, _lpOwner);
        } else {
            unstakeAndRedeemNstbl(_user, _trancheId, _lpOwner);
        }
    }

    function stake(address _user, uint256 _amount, uint8 _trancheId, address _destAddress) external authorizedCaller nonReentrant {
        require(_amount + IERC20Helper(nstblToken).balanceOf(stakePool) <= 40*IERC20Helper(nstblToken).totalSupply()/100, "HUB: STAKE_LIMIT_EXCEEDED");
        IStakePool(stakePool).stake(_user, _amount, _trancheId, _destAddress);
        INSTBLToken(nstblToken).sendOrReturnPool(msg.sender, stakePool, _amount);
    }

    function redeemNormal(uint256 _amount, address _user) internal {
        uint256 liquidTokens = liquidPercent * _amount / 1e4;
        uint256 tBillTokens = tBillPercent * _amount / 1e4;
        uint256 availAssets;
        uint256 assetsLeft = _amount;
        uint256 adjustedDecimals;
        IERC20Helper(nstblToken).burn(msg.sender, _amount);
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

    function unstakeNstbl(address _user, uint8 _trancheId, bool _depeg, address _lpOwner) internal {
        uint256 tokensUnstaked = IStakePool(stakePool).unstake(_user, _trancheId, _depeg, _lpOwner);
        INSTBLToken(nstblToken).sendOrReturnPool(stakePool, msg.sender, tokensUnstaked);
    }

    function unstakeAndRedeemNstbl(address _user, uint8 _trancheId, address _lpOwner) internal {

        (address[] memory _failedAssets, uint256[] memory _failedAssetsPrice) =
            _failedAssetsOrderWithPrice(_noOfFailedAssets());
        (address[] memory _assets, uint256[] memory _assetAmounts, uint256 _unstakeBurnAmount, uint256 _burnAmount) =
            _getStakerRedeemParams(_user, _trancheId, _failedAssets, _failedAssetsPrice);
            console.log("itna burn hoga", _unstakeBurnAmount);
            console.log("atvl se itna burn hoga", _burnAmount);
        _unstakeAndBurnNstbl(_user, _trancheId, _lpOwner, _unstakeBurnAmount);
        _burnNstblFromAtvl(_burnAmount);
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] != address(0)) {
                IERC20Helper(_assets[i]).safeTransfer(msg.sender, _assetAmounts[i]);
            }
        }
    }

    function _getStakerRedeemParams(
        address _user,
        uint8 _trancheId,
        address[] memory _failedAssets,
        uint256[] memory _failedAssetsPrice
    ) internal view returns (address[] memory, uint256[] memory, uint256 _unstakeBurnAmount, uint256 _burnAmount) {
        address[] memory _assets = new address[](_failedAssets.length);
        uint256[] memory _assetAmount = new uint256[](_failedAssets.length);
        uint256 assetsLeft = IStakePool(stakePool).getUserAvailableTokens(_user, _trancheId) * precision;
        uint256 redeemableNstbl;
        uint256 assetBalance;
        uint256 assetRequired;
        uint256 targetPrice;
        uint256 adjustedDecimals;
        for (uint256 i = 0; i < _failedAssets.length; i++) {
            if (_failedAssetsPrice[i] > ub) {
                targetPrice = dt;
            } else {
                targetPrice = _failedAssetsPrice[i] + 4e6;
            }

            _assets[i] = _failedAssets[i];
            adjustedDecimals = IERC20Helper(nstblToken).decimals() - IERC20Helper(_failedAssets[i]).decimals();
            assetRequired = assetsLeft * targetPrice / (_failedAssetsPrice[i] * 10**adjustedDecimals);
            assetBalance = IERC20Helper(_failedAssets[i]).balanceOf(address(this)) * precision;

            if (assetRequired <= assetBalance) {
                _assetAmount[i] = assetRequired / precision;
                _unstakeBurnAmount += (assetsLeft / precision);
                console.log("IDHR?");
                console.log(_unstakeBurnAmount);

                _burnAmount += ((assetRequired*10**adjustedDecimals - assetsLeft)/precision);
                assetsLeft -= assetsLeft;
                break;
            } else {
                redeemableNstbl = assetBalance * 10**adjustedDecimals * _failedAssetsPrice[i] / targetPrice;

                _assetAmount[i] = assetBalance / precision;
                _unstakeBurnAmount += redeemableNstbl/precision;
                console.log("Ya IDHR?");
                console.log(_unstakeBurnAmount);


                _burnAmount += ((assetBalance*10**adjustedDecimals) - redeemableNstbl)/precision;
                assetsLeft -= redeemableNstbl;
            }
        }

        return (_assets, _assetAmount, _unstakeBurnAmount, _burnAmount);
    }

    function _unstakeAndBurnNstbl(address _user, uint8 _trancheId, address _lpOwner, uint256 _unstakeBurnAmount) internal {
        uint256 unstakedTokens = IStakePool(stakePool).unstake(_user, _trancheId, true, _lpOwner);
        console.log("Unstake burn AMount", _unstakeBurnAmount);
        console.log("Unstaked Tokens", unstakedTokens);
        IERC20Helper(nstblToken).burn(stakePool, _unstakeBurnAmount);
        INSTBLToken(nstblToken).sendOrReturnPool(stakePool, msg.sender, unstakedTokens-_unstakeBurnAmount);

    }

    function _burnNstblFromAtvl(uint256 _burnAmount) internal {
        atvlBurnAmount += _burnAmount;
        IATVL(atvl).burnNstbl(_burnAmount);
    }

    function redeemForNonStaker(uint256 _amount, address _user) internal {
        localVars memory vars;
        uint256 precisionAmount = _amount * precision;

        IERC20Helper(nstblToken).burn(msg.sender, _amount);
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
                vars.remainingNstbl = _transferNormal(_user, sortedAssets[i], vars.assetRequired, vars.assetBalance, vars.adjustedDecimals);
            } else {

                vars.assetProportion = (
                    (assetAllocation[sortedAssets[i]] * precisionAmount / 1e5) + vars.remainingNstbl 
                ) / 10 ** vars.adjustedDecimals;
                vars.assetRequired = vars.assetProportion * dt / sortedAssetsPrice[i];

                (vars.remainingNstbl, vars.burnAmount) = _transferBelowDepeg(
                    _user,
                    sortedAssets[i],
                    vars.assetProportion,
                    vars.assetRequired,
                    vars.assetBalance,
                    vars.adjustedDecimals,
                    vars.burnAmount,
                    sortedAssetsPrice[i]
                );
                
                vars.stakePoolBurnAmount +=
                    vars.burnFromStakePool ? _stakePoolBurnAmount(vars.remainingNstbl, vars.assetRequired, vars.assetProportion) : 0;
            }
        }
        _burnNstblFromAtvl((vars.burnAmount - vars.stakePoolBurnAmount));
        _burnNstblFromStakePool(vars.stakePoolBurnAmount);
        requestTBillWithdraw(_amount * 7e4 / 1e5);

    }

    function _transferNormal(
        address _user,
        address _asset,
        uint256 _assetRequired,
        uint256 _assetBalance,
        uint256 _adjustedDecimals
    ) internal returns (uint256 _remainingNstbl) {
        if (_assetRequired <= _assetBalance * 10 ** _adjustedDecimals) {
            IERC20Helper(_asset).safeTransfer(_user, _assetRequired / (precision * 10 ** _adjustedDecimals));
            _remainingNstbl = 0;
        } else {
            IERC20Helper(_asset).safeTransfer(_user, _assetBalance / precision);

            _remainingNstbl = (_assetRequired - _assetBalance * 10 ** _adjustedDecimals);
        }
    }

    function _transferBelowDepeg(
        address _user,
        address _asset,
        uint256 _assetProportion,
        uint256 _assetRequired,
        uint256 _assetBalance,
        uint256 _adjustedDecimals,
        uint256 _burnAmount,
        uint256 _assetPrice
    ) internal returns (uint256, uint256) {
        uint256 _remainingNstbl;
        uint256 redeemableNstbl;
        if (_assetRequired <= _assetBalance) {
            IERC20Helper(_asset).safeTransfer(_user, _assetRequired / precision);

            _remainingNstbl = 0;
            _burnAmount += (_assetRequired - _assetProportion) * 10 ** _adjustedDecimals / precision;
        } else {
            redeemableNstbl = _assetBalance * _assetPrice / dt;
            _burnAmount += (_assetBalance - redeemableNstbl) * 10 ** _adjustedDecimals / precision;
            _remainingNstbl = (_assetProportion - redeemableNstbl) * 10 ** _adjustedDecimals;
            IERC20Helper(_asset).safeTransfer(_user, _assetBalance / precision);
        }
        return(_remainingNstbl, _burnAmount);
    }

    function _stakePoolBurnAmount(uint256 _remNSTBL, uint256 _assetRequired, uint256 _assetProportion)
        internal
        view
        returns (uint256 _burnAmount)
    {
        
        _burnAmount = (_assetRequired - _assetProportion) - (_assetProportion * dt / ub - _assetProportion);
        _burnAmount /= precision;
    }

    function updateAssetAllocation(address _asset, uint256 _allocation) external onlyAdmin {
        assetAllocation[_asset] = _allocation;
    }

    function updateAssetFeeds(address[3] memory _assetFeeds) external onlyAdmin {
        assetFeeds[0] = _assetFeeds[0];
        assetFeeds[1] = _assetFeeds[1];
        assetFeeds[2] = _assetFeeds[2];
    }

    function _failedAssetsOrderWithPrice(uint256 _size) internal view returns (address[] memory, uint256[] memory) {
        uint256 count;
        address[] memory _assetsList = new address[](_size);
        uint256[] memory _assetsPrice = new uint256[](_size);
        uint256 price;
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            if (price <= dt) {
                _assetsList[count] = (assets[i]);
                _assetsPrice[count] = (price);
                count += 1;
            }
        }
        for (uint256 i = 0; i < count - 1; i++) {
            if (_assetsPrice[i] > _assetsPrice[i + 1]) {
                (_assetsList[i], _assetsList[i + 1]) = (_assetsList[i + 1], _assetsList[i]);
                (_assetsPrice[i], _assetsPrice[i + 1]) = (_assetsPrice[i + 1], _assetsPrice[i]);
            }
        }
        if (count > 1 && _assetsPrice[0] > _assetsPrice[1]) {
            (_assetsList[0], _assetsList[1]) = (_assetsList[1], _assetsList[0]);
            (_assetsPrice[0], _assetsPrice[1]) = (_assetsPrice[1], _assetsPrice[0]);
        }
        return (_assetsList, _assetsPrice);
    }

    function _noOfFailedAssets() internal view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            if (IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]) < dt) {
                count += 1;
            }
        }
        return count;
    }

    function _getSortedAssetsWithPrice() internal view returns (address[] memory, uint256[] memory) {
        address[] memory _assets = new address[](assets.length);
        uint256[] memory _assetsPrice = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            _assets[i] = assets[i];
            _assetsPrice[i] = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
        }

        for (uint256 i = 0; i < assets.length - 1; i++) {
            if (_assetsPrice[i] > _assetsPrice[i + 1]) {
                (_assets[i], _assets[i + 1]) = (_assets[i + 1], _assets[i]);
                (_assetsPrice[i], _assetsPrice[i + 1]) = (_assetsPrice[i + 1], _assetsPrice[i]);
            }
        }

        if (_assetsPrice[0] > _assetsPrice[1]) {
            (_assets[0], _assets[1]) = (_assets[1], _assets[0]);
            (_assetsPrice[0], _assetsPrice[1]) = (_assetsPrice[1], _assetsPrice[0]);
        }
        return (_assets, _assetsPrice);
    }

    function setSystemParams(uint256 _dt, uint256 _ub, uint256 _lb, uint256 _liquidPercent, uint256 _tBillPercent)
        external
        onlyAdmin
    {
        dt = _dt;
        ub = _ub;
        lb = _lb;
        liquidPercent = _liquidPercent;
        tBillPercent = _tBillPercent;
    }

    function _burnNstblFromStakePool(uint256 _amount) internal { 
        burnedFromStakePool += _amount;
        if(_amount != 0){
            IStakePool(stakePool).burnNSTBL(_amount);
        }
    }

    function requestTBillWithdraw(uint256 _amount) internal {  
        if(ILoanManager(loanManager).awaitingRedemption()){
            uint256 usdcReceived = _redeemTBill();
        }
        else{
            uint256 lUSDCSupply = ILoanManager(loanManager).getLPTotalSupply();
            uint256 lmTokenAmount = ((_amount)/1e12) * lUSDCSupply / ILoanManager(loanManager).getAssets(lUSDCSupply);

            lmTokenAmount <= lUSDCSupply ? ILoanManager(loanManager).requestRedeem(lmTokenAmount) : ILoanManager(loanManager).requestRedeem(lUSDCSupply);
        }
        
    }

    function processTBillWithdraw() external authorizedCaller returns(uint256){ 
        require(ILoanManager(loanManager).awaitingRedemption(), "HUB: No redemption requested");
        return _redeemTBill();
    }

    function _redeemTBill() internal returns(uint256){
        uint256 balBefore = IERC20Helper(USDC).balanceOf(address(this));
        ILoanManager(loanManager).redeem();
        uint256 balAfter = IERC20Helper(USDC).balanceOf(address(this));
        usdcRedeemed += (balAfter - balBefore);
        IStakePool(stakePool).updatePoolFromHub(true, balAfter - balBefore, 0);
        return(balAfter - balBefore);
    }

    function retrieveFunds(address _asset, uint256 _amount) external onlyAdmin {
        IERC20Helper(_asset).safeTransfer(msg.sender, _amount);
    }
}
