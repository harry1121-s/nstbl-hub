pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NSTBLHUBStorage.sol";

contract NSTBLHub is NSTBLHUBStorage {
    using SafeERC20 for IERC20Helper;

    uint256 private _locked = 1;

    modifier onlyAdmin() {
        require(msg.sender == admin, "HUB::NOT_ADMIN");
        _;
    }

    modifier authorizedCaller() {
        require(msg.sender == nealthyAddr, "HUB::UNAUTH");
        _;
    }

    modifier nonReentrant() {
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
        address _atvl,
        address _admin
    ) {
        nealthyAddr = _nealthyAddr;
        nstblToken = _nstblToken;
        stakePool = _stakePool;
        chainLinkPriceFeed = _chainLinkPriceFeed;
        atvl = _atvl;
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
        _reinvestAssets(_amount1 * 7 / 8);
    }

    function _checkValidDepositEvent() internal {
        for (uint256 i = 0; i < assetFeeds.length; i++) {
            uint256 price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            require(price > dt, "HUB::INVALID_DEPOSIT_EVENT");
        }
        // require(true);
    }

    function _validateEquilibrium(uint256 _amount1, uint256 _amount2, uint256 _amount3) internal {
        //TODO: check equilibrium
        require(true);
    }

    function _reinvestAssets(uint256 _amount) internal {
        IERC20Helper(assets[0]).approve(loanManager, _amount);
        ILoanManager(loanManager).deposit(assets[0], _amount);
    }

    function redeem(uint256 _amount, address _user) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(); //usdc

        if (p1 > dt && p2 > dt && p3 > dt) {
            redeemNormal(_amount, _user);
        } else {
            redeemForNonStaker(_amount, _user);
        }
    }

    function unstake(uint256 _amount, uint256 _poolId, address _user) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();

        if (p1 > dt && p2 > dt && p3 > dt) {
            unstakeNstbl(_amount, _poolId, _user);
        } else {
            unstakeAndRedeemNstbl(_amount, _poolId, _user);
        }
    }

    function stake(uint256 _amount, uint256 _poolId, address user) external authorizedCaller nonReentrant {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice();
        require(p1 > dt && p2 > dt && p3 > dt, "VAULT:STAKING_SUSPENDED");
        IERC20Helper(nstblToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Helper(nstblToken).safeIncreaseAllowance(stakePool, _amount);
        IStakePool(stakePool).stake(_amount, user, _poolId);
    }

    function redeemNormal(uint256 _amount, address _user) public authorizedCaller {
        uint256 liquidTokens = liquidPercent * _amount / 1e5;
        uint256 tBillTokens = tBillPercent * _amount / 1e5;
        uint256 availAssets;
        uint256 assetsLeft = _amount;

        for (uint256 i = 0; i < assets.length; i++) {
            if (i == 0) {
                availAssets = liquidTokens + tBillTokens <= IERC20Helper(assets[i]).balanceOf(address(this))
                    ? liquidTokens + tBillTokens
                    : IERC20Helper(assets[i]).balanceOf(address(this));
            } else {
                availAssets = liquidTokens <= IERC20Helper(assets[i]).balanceOf(address(this))
                    ? liquidTokens
                    : IERC20Helper(assets[i]).balanceOf(address(this));
            }
            IERC20Helper(assets[i]).safeTransfer(_user, availAssets);
            assetsLeft -= availAssets;
        }
        if (assetsLeft > 0) {
            addToWithdrawalQueue(_user, assetsLeft);
        }
        processTBillWithdraw(tBillTokens);
    }

    function unstakeNstbl(uint256 _amount, uint256 _poolId, address _user) internal {
        uint256 balBefore = IERC20Helper(nstblToken).balanceOf(address(this));
        IStakePool(stakePool).unstake(_amount, _user, _poolId);
        uint256 balAfter = IERC20Helper(nstblToken).balanceOf(address(this));
        IERC20Helper(nstblToken).safeTransfer(msg.sender, balAfter - balBefore);
    }

    function unstakeAndRedeemNstbl(uint256 _amount, uint256 _poolId, address _user) internal {
        (address[] memory _failedAssets, uint256[] memory _failedAssetsPrice) =
            _failedAssetsOrderWithPrice(_noOfFailedAssets());
        (address[] memory _assets, uint256[] memory _assetAmounts, uint256 _unstakeAmount, uint256 _burnAmount) =
            _getStakerRedeemParams(_amount, _poolId, _user, _failedAssets, _failedAssetsPrice);
        _unstakeAndBurnNstbl(_user, _unstakeAmount / precision, _poolId);
        _burnNstblFromAtvl(_burnAmount / precision);
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] != address(0)) {
                IERC20Helper(_assets[i]).safeTransfer(msg.sender, _assetAmounts[i]);
            }
        }
    }

    function _getStakerRedeemParams(
        uint256 _amount,
        uint256 _poolId,
        address _user,
        address[] memory _failedAssets,
        uint256[] memory _failedAssetsPrice
    ) internal view returns (address[] memory, uint256[] memory, uint256 _unstakeAmount, uint256 _burnAmount) {
        address[] memory _assets = new address[](_failedAssets.length);
        uint256[] memory _assetAmount = new uint256[](_failedAssets.length);
        // uint256 _unstakeAmount;
        // uint256 _burnAmount;
        require(_getStakedAmount(_user, _poolId) >= _amount, "VAULT::INVALID_AMOUNT");
        uint256 assetsLeft = _amount * precision;
        uint256 redeemableNstbl;
        uint256 assetBalance;
        uint256 assetRequired;
        uint256 targetPrice;

        for (uint256 i = 0; i < _failedAssets.length; i++) {
            if (_failedAssetsPrice[i] > ub) {
                targetPrice = dt;
            } else if (_failedAssetsPrice[i] > lb) {
                targetPrice = 1e8;
            } else {
                targetPrice = _failedAssetsPrice[i] + 4e6;
            }

            // _assets.push(_failedAssets[i]);
            _assets[i] = _failedAssets[i];

            assetRequired = assetsLeft * targetPrice / _failedAssetsPrice[i];
            assetBalance = IERC20Helper(_failedAssets[i]).balanceOf(address(this)) * precision;

            if (assetRequired <= assetBalance) {
                // _assetAmount.push(assetRequired/precision);
                _assetAmount[i] = assetRequired / precision;
                _unstakeAmount += assetsLeft;

                _burnAmount += assetRequired - assetsLeft;
                assetsLeft -= assetsLeft;
                break;
            } else {
                redeemableNstbl = assetBalance * _failedAssetsPrice[i] / targetPrice;

                // _assetAmount.push(assetBalance/precision);
                _assetAmount[i] = assetBalance / precision;
                _unstakeAmount += redeemableNstbl;

                _burnAmount += assetBalance - redeemableNstbl;
                assetsLeft -= redeemableNstbl;
            }
        }
        return (_assets, _assetAmount, _unstakeAmount, _burnAmount);
    }

    function _unstakeAndBurnNstbl(address _user, uint256 _unstakeAmount, uint256 _poolId) internal {
        uint256 balBefore = IERC20Helper(nstblToken).balanceOf(address(this));
        IStakePool(stakePool).unstake(_unstakeAmount, _user, _poolId);
        uint256 balAfter = IERC20Helper(nstblToken).balanceOf(address(this));
        IERC20Helper(nstblToken).burn(address(this), balAfter - balBefore);
    }

    function _burnNstblFromAtvl(uint256 _burnAmount) internal {
        atvlBurnAmount += _burnAmount;
        IATVL(atvl).burnNstbl(_burnAmount);
    }

    function redeemForNonStaker(uint256 _amount, address _user) public authorizedCaller {
        bool belowDT;
        bool burnFromStakePool;
        uint256 precisionAmount = _amount * precision;
        uint256 assetBalance;
        uint256 assetProportion;
        uint256 assetRequired;
        uint256 redeemableNstbl;
        uint256 remainingNstbl;
        uint256 burnAmount;
        uint256 stakePoolBurnAmount;

        (address[] memory sortedAssets, uint256[] memory sortedAssetsPrice) = _getSortedAssetsWithPrice();
        for (uint256 i = 0; i < sortedAssets.length; i++) {
            if (sortedAssetsPrice[i] < dt) {
                belowDT = true;
                if (sortedAssetsPrice[i] < lb) {
                    burnFromStakePool = true;
                } else {
                    burnFromStakePool = false;
                }
            } else {
                belowDT = false;
            }

            assetBalance = IERC20Helper(sortedAssets[i]).balanceOf(address(this)) * precision;

            if (!belowDT) {
                assetRequired = assetAllocation[sortedAssets[i]] * precisionAmount / 1e5 + remainingNstbl;
                if (assetRequired <= assetBalance) {
                    IERC20Helper(sortedAssets[i]).safeTransfer(_user, assetRequired / precision);
                    // assetsLeft -= assetRequired;
                    remainingNstbl = 0;
                } else {
                    IERC20Helper(sortedAssets[i]).safeTransfer(_user, assetBalance / precision);
                    // assetsLeft -= assetBalance;
                    remainingNstbl = assetRequired - assetBalance;
                }
            }
            else{
                assetProportion = assetAllocation[sortedAssets[i]] * precisionAmount / 1e5 + remainingNstbl;
                assetRequired = assetProportion * dt / sortedAssetsPrice[i];
                if (assetRequired <= assetBalance) {
                    IERC20Helper(sortedAssets[i]).safeTransfer(_user, assetRequired / precision);
                    remainingNstbl = 0;
                    burnAmount += assetRequired - assetProportion;
                    // assetsLeft -= assetRequired;
                } else {
                    redeemableNstbl = assetBalance * sortedAssetsPrice[i] / dt;
                    burnAmount += assetBalance - redeemableNstbl;
                    remainingNstbl = assetProportion - redeemableNstbl;
                    IERC20Helper(sortedAssets[i]).safeTransfer(_user, assetBalance / precision);
                }
                if (burnFromStakePool) {
                    if (remainingNstbl == 0) {
                        stakePoolBurnAmount +=
                            (assetRequired - assetProportion) - (assetProportion * dt / ub - assetProportion);
                    } else {
                        stakePoolBurnAmount +=
                            (assetBalance - redeemableNstbl) - (redeemableNstbl * dt / ub - redeemableNstbl);
                    }
                }
            }
        }
        _burnNstblFromAtvl((burnAmount - stakePoolBurnAmount) / precision);
        _burnNstblFromStakePool(stakePoolBurnAmount / precision);
        addToWithdrawalQueue(_user, remainingNstbl / precision);
        processTBillWithdraw(_amount * tBillPercent / 1e5);
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
            if (price < dt) {
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

    function _getSortedAssetsWithPrice()
        internal
        view
        returns (address[] memory _assets, uint256[] memory _assetsPrice)
    {
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
    }

    function _getStakedAmount(address _user, uint256 _poolId) internal view returns (uint256 _amount) {
        _amount = IStakePool(stakePool).getUserStakedAmount(_user, _poolId);
    }

    function totalLiquidAssets() public view returns (uint256 _assets) {
        for (uint256 i = 0; i < assets.length; i++) {
            _assets += IERC20Helper(assets[i]).balanceOf(address(this));
        }
    }

    function updateAuthorizedCaller(address _caller) external onlyAdmin {
        nealthyAddr = _caller;
    }

    function updateAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setSystemParams(uint256 _dt, uint256 _ub, uint256 _lb) external onlyAdmin {
        dt = _dt;
        ub = _ub;
        lb = _lb;
    }

    function addToWithdrawalQueue(address _user, uint256 _amount) internal {}

    function _burnNstblFromStakePool(uint256 _amount) internal {}

    function processTBillWithdraw(uint256 _amount) internal {}
}
