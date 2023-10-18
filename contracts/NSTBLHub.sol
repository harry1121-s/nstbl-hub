pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Helper, IStakePool, ILoanManager, IChainlinkPriceFeed, NSTBLHUBStorage} from "./NSTBLHUBStorage.sol";
 
contract NSTBLHub is NSTBLHUBStorage{
    using SafeERC20 for IERC20Helper;

    uint256 private _locked = 1;

    modifier onlyAdmin {
        require(msg.sender == admin, "HUB::NOT_ADMIN");
        _;
    }

    modifier authorizedCaller(){
        require(msg.sender == nealthyAddr, "HUB::UNAUTH");
        _;
    }

    modifier nonReentrant(){
        require(_locked == 1, "HUB::REENTRANT");
        _locked = 2;
        _;
        _locked = 1;
    }

    constructor(
        address _nealthyAddr, 
        address _nstblToken,
        address _stakePool,
        address _chainLinkPriceFeed,
        address _admin
    ){
        nealthyAddr = _nealthyAddr;
        nstblToken = _nstblToken;
        stakePool = _stakePool;
        chainLinkPriceFeed = _chainLinkPriceFeed;
        admin = _admin;
    }

    function deposit(uint256 _amount1, uint256 _amount2, uint256 _amount3) external authorizedCaller {
        
        _checkValidDepositEvent();
        _validateEquilibrium(_amount1, _amount2, _amount3);

        IERC20Helper(assets[0]).safeTransferFrom(msg.sender, address(this), _amount1);
        IERC20Helper(assets[1]).safeTransferFrom(msg.sender, address(this), _amount2);
        IERC20Helper(assets[2]).safeTransferFrom(msg.sender, address(this), _amount3);

        uint256 nstblTokenAmount = _amount1 + _amount2 + _amount3;

        IERC20Helper(nstblToken).mint(msg.sender, nstblTokenAmount);
        _reinvestAssets(_amount1*7/8);


    }

    function _checkValidDepositEvent() internal {
        // for(uint256 i = 0; i<assetFeeds.length; i++){
        //     uint256 price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
        //     require(price > dt, "HUB::INVALID_DEPOSIT_EVENT");
        // }
        require(true);
    }

    function _validateEquilibrium(uint256 _amount1, uint256 _amount2, uint256 _amount3) internal {
        //TODO: check equilibrium
        require(true);
    }

    function _reinvestAssets(uint256 _amount) internal {
        IERC20Helper(assets[0]).approve(loanManager, _amount);
        ILoanManager(loanManager).deposit(assets[0], _amount);
    }


    // function redeem(uint256 _amount, address _user) external authorizedCaller nonReentrant{
    //     (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(); //usdc

    //     if(p1 >dt && p2 > dt && p3 > dt){ 
    //         redeemNormal(_amount, _user);
    //     }
    //     else{  
    //         redeemForNonStaker(_amount, _user);   
    //     }
            
    // }

    function unstake(uint256 _amount, uint256 _poolId, address _user) external authorizedCaller nonReentrant{
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        if(p1 >dt && p2 > dt && p3 > dt){
            unstakeNstbl(_amount, _poolId, _user);
        }
        else{  
            unstakeAndRedeemNstbl(_amount, _poolId, _user);
        }
    }

    function stake(uint256 _amount, uint256 _poolId, address user) external authorizedCaller nonReentrant{
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        require(p1>dt && p2>dt && p3>dt, "VAULT:STAKING_SUSPENDED");
        IERC20Helper(nstblToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Helper(nstblToken).safeIncreaseAllowance(stakePool, _amount);
        IStakePool(stakePool).stake(_amount, user, _poolId);
    }

    function _isStaker(address _user) internal returns(bool ifStaker) {
        //TODO: 
        ifStaker = true;
    }


    // function redeemNormal(uint256 _amount, address _user) public authorizedCaller {
    //     uint256 liquidTokens = liquidPercent*_amount/1e5;
    //     uint256 tBillTokens = tBillPercent*_amount/1e5;
    //     uint256 availAssets;
    //     uint256 assetsLeft = _amount;
       

    //     if(_amount< withdrawalMargin(false)){
    //         for(uint256 i=0; i<assets.length;i++){
    //             if(i==0)
    //                 availAssets = liquidTokens+tBillTokens<=IERC20Helper(assets[i]).balanceOf(address(this)) ? liquidTokens+tBillTokens : IERC20Helper(assets[i]).balanceOf(address(this));
    //             else
    //                 availAssets = liquidTokens<=IERC20Helper(assets[i]).balanceOf(address(this)) ? liquidTokens : IERC20Helper(assets[i]).balanceOf(address(this));
    //             IERC20Helper(assets[i]).safeTranfer(_user, availAssets);
    //             assetsLeft -= availAssets;
    //         }
    //         if(assetsLeft>0){
    //             addUserToLateWithdrawQueue(_user, assetsLeft);
    //         }
    //     }
    //     else{
    //         addUserToLateWithdrawQueue(_user, _amount);
    //     }
        
    //     processTBillWithdraw(tBillTokens);

    // }

    // function _redeemForNonStaker(uint256 _amount, address _user, uint256 _targetPrice, uint256[] memory _prices)  internal {
    //     uint256 liquidTokens = liquidPercent*_amount/1e5;
    //     uint256 tBillTokens = tBillPercent*_amount/1e5;
    //     uint256 assetsLeft;
    //     uint256 burnAmount;
    //     uint256 poolBurnAmount;

    //     uint256 reqTokens;
    //     uint256 availAssets;
    //     if(_amount< withdrawalMargin(false)){
    //         for(uint256 i=0; i<assets.length;i++){
                
    //             if(i==0){
    //                 reqTokens = _prices[i]<dt ? (liquidTokens+tBillTokens)*_targetPrice/_prices[i] : liquidTokens+tBillTokens;
    //                 availAssets = reqTokens<=IERC20Helper(assets[i]).balanceOf(address(this)) ? reqTokens : IERC20Helper(assets[i]).balanceOf(address(this));
    //                 burnAmount += reqTokens-(liquidTokens+tBillTokens);
                    
    //             }
    //             else{
    //                 reqTokens = _prices[i]<dt ? liquidTokens*_targetPrice/prices[i] : liquidTokens;
    //                 availAssets = reqTokens<=IERC20Helper(assets[i]).balanceOf(address(this)) ? reqTokens : IERC20Helper(assets[i]).balanceOf(address(this));
    //                 burnAmount += reqTokens-liquidTokens;
    //             }
    //             assetsLeft += reqTokens-availAssets;
    //             IERC20Helper(assets[i]).safeTranfer(_user, availAssets);
    //             if(_prices[i]<lb){
    //                     poolBurnAmount += reqTokens *_targetPrice/_prices[i] - reqTokens*_targetPrice/lb;     
    //             }
    //         }
    //         if(assetsLeft>0){
    //             addUserToLateWithdrawQueue(_user, assetsLeft)
    //         }
    //     }
    //     else{
    //         addUserToLateWithdrawQueue(_user, _amount);
    //     }
    //     burnNSTBLForRedemption(burnAmount, poolBurnAmount);
    //     processTBillRedemption(tBillTokens);
    // }

    // function _redeemWithExtraCAForStaker(uint256 _amount, address _user) internal {

    //     uint256 burnAmount;
    //     uint256 amountLeft = _amount;
    //     uint256 poolBurnAmount;
    //     uint256 targetPrice;
    //     uint256 totalPriceLeft;

    //     uint256 availTokens;

    //     unstakeNSTBL(_user, _availableUnstakeAmount(_user, _amount, false));
    //     (uint256[] failedAssets, uint256[] failedAssetsPrice) = _failedAssetsOrderWithPrice();
    //     if(_amount< withdrawalMargin(true) && _targetPrice !=0){
    //         uint256 availAmount = _amount;
    //         uint256 tokensAvailable;
    //         for(uint256 i=0; i<failedAssets.length. i++){
    //             ///////////
    //             if(failedAssetsPrice[i]>ub){
    //                 targetPrice = 98e6;
    //             }
    //             else if(failedAssetsPrice[i]>lb){
    //                 targetPrice = 1e8;
    //             }
    //             else{
    //                 targetPrice = failedAssetsPrice[i]+4e6;
    //             }
    //             totalPriceLeft = amountLeft*targetPrice;
    //             ///////////
    //             availAssetsPrice = IERC20Helper(failedAssets[i]).balanceOf(address(this))*failedAssetsPrice[i];
    //             if(availAssetsPrice>=totalPriceLeft){
    //                 availTokens = totalPriceLeft/failedAssetsPrice[i];
    //                 burnAmount += availTokens - amountLeft;
    //                 totalPriceLeft = 0;
    //             }
    //             else{
    //                 availTokens = availAssetsPrice/failedAssetsPrice[i];
    //                 burnAmount += availTokens - assetsPriceLeft/_targetPrice;
    //                 assetsPriceLeft -= availAssetsPrice;
    //             }
    //             IERC20Helper(failedAssets[i]).safeTranfer(_user, availTokens);
    //         }
    //         if(assetsPriceLeft > 0){
    //             addToWithdrawalQueue(_user, availAmount/_targetPrice, false);
    //             //TODO: add remaining Tokens to queue for redemption at 1:1 rate
    //         }
    //     }
    //     else {
    //         //TODO: queue logic TBA
    //         addToWithdrawalQueue(_user, _amount, false);
    //     }
    //     // else{
    //     //     uint256 assetBalance;
    //     //     for(uint256 i =0; i<failedAssets.length; i++){
    //     //         assetBalance = IERC20Helper(failedAssets[i]).balanceOf(address(this));
    //     //         reqTokens = _amount*(failedAssetsPrice[i]+4e6)/failedAssetsPrice[i];
    //     //         if(reqTokens<=assetBalance){
    //     //             IERC20Helper(failedAssets[i]).safeTranfer(_user, reqTokens);
    //     //             break;
    //     //         }
    //     //         else{
    //     //             IERC20Helper(failedAssets[i]).safeTranfer(_user, assetBalance);
    //     //             amountLeft -= assetBalance*failedAssetsPrice[i]/(failedPrice[i]+4e6);
    //     //         }

    //     //     }
    //     // }
        
    // }
    function unstakeNstbl(uint256 _amount, uint256 _poolId, address _user) internal {
        uint256 balBefore = IERC20Helper(nstblToken).balanceOf(address(this));
        IStakePool(stakePool).unstake(_amount, _user, _poolId);
        uint256 balAfter = IERC20Helper(nstblToken).balanceOf(address(this));
        IERC20Helper(nstblToken).safeTransfer(msg.sender, balAfter-balBefore);
    }
    function unstakeAndRedeemNstbl(uint256 _amount, uint256 _poolId, address _user) internal {

        (address[] memory _failedAssets, uint256[] memory _failedAssetsPrice) = _failedAssetsOrderWithPrice();
        (address[] memory _assets, uint256[] memory _assetAmounts, uint256 _unstakeAmount, uint256 _burnAmount) = _getStakerRedeemParams(_amount, _poolId, _user, _failedAssets, _failedAssetsPrice);
        _unstakeAndBurnNstbl(_user, _unstakeAmount/precision, _poolId);
        _burnNstblFromAtvl(_burnAmount/precision);
        for(uint256 i=0; i<_assets.length; i++){
            IERC20Helper(_assets[i]).safeTransfer(_user, _assetAmounts[i]);
        }

        // for(uint256 i=0; i<failedAssets.length; i++){
        //     if(failedAssetsPrice[i]>ub){
        //         targetPrice = dt;
        //     }
        //     else if(failedAssetsPrice[i]>lb){
        //         targetPrice = 1e8;
        //     }
        //     else{
        //         targetPrice = failedAssetsPrice[i]+4e6;
        //     }

        //     assetRequired = assetsLeft*targetPrice*precision/failedAssetsPrice[i];
        //     assetBalance = IERC20Helper(failedAssets[i]).balanceOf(address(this))*precision;

        //     if(assetRequired<=assetBalance){
        //         IERC20Helper(failedAssets[i]).safeTranfer(_user, assetRequired/precision);
        //         break;
        //     }
        //     else{
        //         redeemableNSTBL = assetBalance*failedAssetsPrice[i]/targetPrice;
        //         nstblBurnAmount += assetBalance-redeemableNSTBL;

        //         IERC20Helper(failedAssets[i]).safeTranfer(_user, assetBalance/precision);
        //         assetsLeft -= redeemableNSTBL;
        //     }
        // }
    }

    function _getStakerRedeemParams(uint256 _amount, uint256 _poolId, address _user, address[] memory _failedAssets, uint256[] memory _failedAssetsPrice) internal view
    returns(address[] memory _assets, uint256[] memory _assetAmount, uint256 _unstakeAmount, uint256 _burnAmount){

        uint256 stakeAmount = _getStakedAmount(_user, _poolId);
        require(stakeAmount>= _amount, "VAULT::INVALID_AMOUNT");
        uint256 assetsLeft = _amount*precision;
        uint256 redeemableNstbl;
        uint256 assetBalance;
        uint256 assetRequired;
        uint256 targetPrice;
        uint256 count = 0;
        for(uint256 i=0; i<_failedAssets.length; i++){

            if(_failedAssetsPrice[i]>ub){
                targetPrice = dt;
            }
            else if(_failedAssetsPrice[i]>lb){
                targetPrice = 1e8;
            }
            else{
                targetPrice = _failedAssetsPrice[i]+4e6;
            }

            // _assets.push(_failedAssets[i]);
            _assets[count] = _failedAssets[i];

            assetRequired = assetsLeft*targetPrice/_failedAssetsPrice[i];
            assetBalance = IERC20Helper(_failedAssets[i]).balanceOf(address(this))*precision;

            if(assetRequired<=assetBalance){
                // _assetAmount.push(assetRequired/precision);
                _assetAmount[count] = assetRequired/precision;
                _unstakeAmount += assetsLeft;

                _burnAmount += assetRequired-assetsLeft;
                assetsLeft -= assetsLeft;
                break;
            }
            else{
                redeemableNstbl = assetBalance*_failedAssetsPrice[i]/targetPrice;

                // _assetAmount.push(assetBalance/precision);
                _assetAmount[count] = assetBalance/precision;
                _unstakeAmount += redeemableNstbl;

                _burnAmount += assetBalance-redeemableNstbl;
                assetsLeft -= redeemableNstbl;
            }
            count+=1;
        }

    }

    function _unstakeAndBurnNstbl(address _user, uint256 _unstakeAmount, uint256 _poolId) internal {
        uint256 balBefore = IERC20Helper(nstblToken).balanceOf(address(this));
        IStakePool(stakePool).unstake(_unstakeAmount, _user, _poolId);
        uint256 balAfter = IERC20Helper(nstblToken).balanceOf(address(this));
        IERC20Helper(nstblToken).burn(address(this), balAfter-balBefore);
    }

    function _burnNstblFromAtvl(uint256 _burnAmount) internal{
        //Saving in storage just for testing, will be removed once atvl is deployed
        atvlBurnAmount = _burnAmount;
        //TODO: burn from atvl
    }

    function redeemForNonStaker(uint256 _amount, address _user) public authorizedCaller {

        bool belowDT;
        bool burnFromStakePool;
        uint256 precisionAmount = _amount*precision;
        uint256 assetBalance;
        uint256 assetProportion;
        uint256 assetRequired;
        uint256 redeemableNstbl;
        uint256 remainingNstbl;
        uint256 burnAmount;
        uint256 stakePoolBurnAmount;

        // (address[] memory sortedAssets, uint256[] memory sortedAssetsPrice) = _getSortedAssetsWithPrice();
        // for(uint256 i=0; i<sortedAssets.length; i++){
        //     if(sortedAssetsPrice[i] < dt){
        //         belowDT = true;
        //         if(sortedAssetsPrice[i] < lb){
        //             burnFromStakePool = true;
        //         }
        //         else{
        //             burnFromStakePool = false;
        //         }
        //     }
        //     else{
        //         belowDT = false;
        //     }

        //     assetBalance = IERC20Helper(sortedAssets[i]).balanceOf(address(this))*precision;

        //     if(!belowDT){
        //         assetRequired = assetAllocation[sortedAssets[i]]*precisionAmount/1e5 + remainingNstbl;
        //         if(assetRequired<=assetBalance){
        //             IERC20Helper(sortedAssets[i]).safeTranfer(_user, assetRequired/precision);
        //             // assetsLeft -= assetRequired;
        //             remainingNstbl = 0;
        //         }
        //         else{
        //             IERC20Helper(sortedAssets[i]).safeTranfer(_user, assetBalance/precision);
        //             // assetsLeft -= assetBalance;
        //             remainingNstbl = assetRequired-assetBalance;
        //         }
        //     }
        //     else{
        //         assetProportion = assetAllocation[sortedAssets[i]]*precisionAmount/1e5 + remainingNstbl;
        //         assetRequired = assetProportion*dt/sortedAssetsPrice[i];
        //         if(assetRequired<=assetBalance){
        //             IERC20Helper(sortedAssets[i]).safeTranfer(_user, assetRequired/precision);
        //             remainingNstbl = 0;
        //             burnAmount += assetRequired-assetProportion;
        //             // assetsLeft -= assetRequired;
        //         }
        //         else{
        //             redeemableNstbl = assetBalance*sortedAssetsPrice[i]/dt;
        //             burnAmount += assetBalance-redeemableNstbl;
        //             remainingNstbl = assetProportion-redeemableNstbl;
        //             IERC20Helper(sortedAssets[i]).safeTranfer(_user, assetBalance/precision);
        //         }
        //         if(burnFromStakePool){
        //             if(remainingNstbl==0){
        //                 stakePoolBurnAmount += (assetRequired-assetProportion) - (assetProportion*dt/ub - assetProportion);
        //             }
        //             else{
        //                 stakePoolBurnAmount += (assetBalance-redeemableNstbl) - (redeemableNstbl*dt/ub - redeemableNstbl);
        //             }
        //         }
        //     }

            
        // }
        // _burnNstblFromAtvl((burnAmount-stakePoolBurnAmount)/precision);
        // _burnNstblFromStakePool(stakePoolBurnAmount/precision);
        // addToWithdrawalQueue(_user, remainingNstbl/precision);
        // processTBillWithdraw(_amount*tBillPercent/1e5);
    }

    function _failedAssetsOrderWithPrice() internal view returns(address[] memory _assetsList, uint256[] memory _assetsPrice){
        uint256 price;
        uint256 count;
        for(uint256 i=0; i<assetFeeds.length; i++){
            price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            if(price<dt){
                _assetsList[count]=assets[i];
                _assetsPrice[count]=price;
                count+=1;
            }
        }
        for(uint256 i=0; i<count-1; i++)
        {
            if(_assetsPrice[i]>_assetsPrice[i+1]){
                    (_assetsList[i], _assetsList[i+1]) = (_assetsList[i+1], _assetsList[i]);
                    (_assetsPrice[i], _assetsPrice[i+1]) = (_assetsPrice[i+1], _assetsPrice[i]);
            }  
        }
        if(count>1 && _assetsPrice[0]>_assetsPrice[1]){
                (_assetsList[0], _assetsList[1]) = (_assetsList[1], _assetsList[0]);
                (_assetsPrice[0], _assetsPrice[1]) = (_assetsPrice[1], _assetsPrice[0]);
        }
    }

    function _getSortedAssetsWithPrice() internal view returns(address[] memory _assets, uint256[] memory _assetsPrice){

        for(uint256 i=0; i<assets.length; i++){
            _assets[i] = assets[i];
            _assetsPrice[i] = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
        }


        for(uint256 i=0; i<assets.length-1; i++)
        {
            if(_assetsPrice[i]>_assetsPrice[i+1]){
                (_assets[i], _assets[i+1]) = (_assets[i+1], _assets[i]);
                (_assetsPrice[i], _assetsPrice[i+1]) = (_assetsPrice[i+1], _assetsPrice[i]);
            }
        }

        if(_assetsPrice[0]>_assetsPrice[1]){
                (_assets[0], _assets[1]) = (_assets[1], _assets[0]);
                (_assetsPrice[0], _assetsPrice[1]) = (_assetsPrice[1], _assetsPrice[0]);
        }

    }

    function _getStakedAmount(address _user, uint256 _poolId) internal view returns(uint256 _amount){
        _amount = IStakePool(stakePool).getUserStakedAmount(_user, _poolId);
    }

    function totalLiquidAssets() public view returns(uint256 _assets) {
        for(uint256 i=0; i<assets.length; i++){
            _assets += IERC20Helper(assets[i]).balanceOf(address(this));
        }
    }

    function withdrawalMargin(bool _checkFailingStable) public view returns(uint256 _margin) {
        if(!_checkFailingStable){
            _margin = marginPercent*totalLiquidAssets()/1e5;
        }
        else{
            for(uint256 i=0; i<assetFeeds.length; i++){
                if(IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i])<dt){
                    _margin += marginPercent*IERC20Helper(assets[i]).balanceOf(address(this))/1e5;
                }
            }
        }
    }

    function updateAuthorizedCaller(address _caller) public onlyAdmin {
        nealthyAddr = _caller;
    }

    function updateAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function setSystemParams(uint256 _dt, uint256 _ub, uint256 _lb) public onlyAdmin {
        dt = _dt;
        ub = _ub;
        lb = _lb;
    }
    
    
    
}