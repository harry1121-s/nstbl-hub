pragma solidity 0.8.21;

import "./interfaces/IChainlinkPriceFeed.sol";

contract eqLogic {
    address public priceFeed;
    uint256 public dt;
    uint256 public precision = 1e18;

    constructor(address _priceFeed, uint256 _dt) {
        priceFeed = _priceFeed;
        dt = _dt;
    }

    function deposit(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt) external {
        (uint256 a1, uint256 a2, uint256 a3) = _getSystemAllocation(_usdcAmt, _usdtAmt, _daiAmt);
        uint256 tAlloc = a1 + a2 + a3;
        uint256[] memory balances = _getAssetBalances();
        uint256 tvlOld = balances[0] + balances[1] + balances[2];
        uint256 tvlNew = tvlOld + _usdcAmt + _usdtAmt + _daiAmt;

        uint256[] memory cr = new uint256[](3);

        cr[0] = a1 != 0 ? (balances[0] * tAlloc * precision) / (a1 * tvlOld) : 0;
        cr[1] = a2 != 0 ? (balances[1] * tAlloc * precision) / (a2 * tvlOld) : 0;
        cr[2] = a3 != 0 ? (balances[2] * tAlloc * precision) / (a3 * tvlOld) : 0;

        uint256 oldEq = _calcEq(cr[0], cr[1], cr[2]);

        cr[0] = a1 != 0 ? ((balances[0] + _usdcAmt) * tAlloc * precision) / (a1 * tvlNew) : 0;
        cr[1] = a2 != 0 ? ((balances[1] + _usdtAmt) * tAlloc * precision) / (a2 * tvlNew) : 0;
        cr[2] = a3 != 0 ? ((balances[2] + _daiAmt) * tAlloc * precision) / (a3 * tvlNew) : 0;

        uint256 newEq = _calcEq(cr[0], cr[1], cr[2]);

        require(newEq <= oldEq || newEq < eqTh, "HUB::Deposit Not Allowed");

        //Deposit required Tokens
        IERC20Helper(USDC).safeTransferFrom(msg.sender, address(this), _usdcAmt);
        if(a2!=0){
            IERC20Helper(USDT).safeTransferFrom(msg.sender, address(this), _usdtAmt);
        }
        if(a3!=0){
            IERC20Helper(DAI).safeTransferFrom(msg.sender, address(this), _daiAmt);
        }

        _investUSDC(7e3*_usdcAmt/a1);
        IERC20Helper(nstblToken).mint(msg.sender, _usdcAmt+_usdtAmt+_daiAmt);


    }

    function _calcEq(uint256 cr1, uint256 cr2, uint256 cr3) internal pure returns (uint256 _eq) {
        _eq = (modSub(cr1) + modSub(cr2) + modSub(cr3)) / 3;
    }

    //TODO: add inputs amts here and revert in if-else block
    function _getSystemAllocation() internal view returns (uint256 _a1, uint256 _a2, uint256 _a3) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(priceFeed).getLatestPrice();

        require(p1 > dt, "VAULT: Deposits Halted");

        if (p2 > dt && p3 > dt) {
            _a1 = 8e3;
            _a2 = 1e3;
            _a3 = 1e3;
        } else if (p2 > dt && p3 < dt) {
            _a1 = 9e3;
            _a2 = 1e3;
            _a3 = 0;
        } else if (p2 < dt && p3 > dt) {
            _a1 = 9e3;
            _a2 = 0;
            _a3 = 1e3;
        } else {
            _a1 = 10e3;
            _a2 = 0;
            _a3 = 0;
        }
    }

    function modSub(uint256 _a) internal pure returns (uint256) {
        if(_a!=0){
            return _a > precision ? _a - precision : precision - _a;
        }
        else{
            return 0;
        }
    }

    function _getAssetBalances() internal view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ILoanManager(loanManager).getAssets(USDC) + IERC20Helper(USDC).balanceOf(address(this));
        balances[1] = IERC20Helper(USDT).balanceOf(address(this));
        balances[2] = IERC20Helper(DAI).balanceOf(address(this));

        return balances;
    }
}
