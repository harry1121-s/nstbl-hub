pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/ILoanManager.sol";
import { IERC20, IERC20Helper } from "./interfaces/IERC20Helper.sol";
import { console } from "forge-std/Test.sol";

contract eqLogic {
    using SafeERC20 for IERC20Helper;
    using SafeERC20 for IERC20;

    address public priceFeed;
    address public loanManager;
    uint256 public dt;
    uint256 public precision = 1e24;
    uint256 public eqTh;
    address public nstblToken;

    uint256 public usdcDeposited;
    uint256 public usdtDeposited;
    uint256 public daiDeposited;

    address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor(address _priceFeed, address _loanManager, address _nstblToken, uint256 _dt, uint256 _eqTh) {
        priceFeed = _priceFeed;
        loanManager = _loanManager;
        nstblToken = _nstblToken;
        dt = _dt;
        eqTh = _eqTh;
    }

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

    function deposit(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt) external {
        console.log("Deposit Called");
        console.log(_usdcAmt, _usdtAmt, _daiAmt);

        (uint256 _a1, uint256 _a2, uint256 _a3) = _validateSystemAllocation(_usdcAmt, _usdtAmt, _daiAmt);
        _checkEquilibrium(_a1, _a2, _a3, _usdcAmt, _usdtAmt, _daiAmt);

        //Deposit required Tokens
        IERC20Helper(USDC).safeTransferFrom(msg.sender, address(this), _usdcAmt);
        usdcDeposited += _usdcAmt;
        if (_a2 != 0) {
            IERC20(USDT).safeTransferFrom(msg.sender, address(this), _usdtAmt);
            usdtDeposited += _usdtAmt;
        }
        if (_a3 != 0) {
            IERC20Helper(DAI).safeTransferFrom(msg.sender, address(this), _daiAmt);
            daiDeposited += _daiAmt;
        }

        _investUSDC(7e3 * _usdcAmt / _a1);
        IERC20Helper(nstblToken).mint(msg.sender, (_usdcAmt + _usdtAmt) * 1e12 + _daiAmt);
    }

    function _validateSystemAllocation(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt)
        internal
        view
        returns (uint256 _a1, uint256 _a2, uint256 _a3)
    {
        (_a1, _a2, _a3) = _getSystemAllocation();
        console.log(_a1, _a2, _a3);
        require(_a2 == 0 ? _usdtAmt == 0 : true, "VAULT: Invalid Deposit");
        require(_a3 == 0 ? _daiAmt == 0 : true, "VAULT: Invalid Deposit");
        require(_usdcAmt + _usdtAmt + _daiAmt != 0, "HUB::Invalid Deposit");
    }

    function _getSystemAllocation() internal view returns (uint256 _a1, uint256 _a2, uint256 _a3) {
        (uint256 p1, uint256 p2, uint256 p3) = IChainlinkPriceFeed(priceFeed).getLatestPrice();

        require(p1 > dt, "VAULT: Deposits Halted");

        if (p2 > dt && p3 > dt) {
            _a1 = 8e3;
            _a2 = 1e3;
            _a3 = 1e3;
        } else if (p2 > dt && p3 < dt) {
            _a1 = 85e2;
            _a2 = 15e2;
            _a3 = 0;
        } else if (p2 < dt && p3 > dt) {
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
    ) internal {
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
        balances[0] = ILoanManager(loanManager).getAssets(USDC) + usdcDeposited * 1e12;
        balances[1] = usdtDeposited * 1e12;
        balances[2] = daiDeposited;

        return balances;
    }

    function _investUSDC(uint256 _amt) internal {
        IERC20Helper(USDC).safeIncreaseAllowance(loanManager, _amt);
        ILoanManager(loanManager).deposit(USDC, _amt);
    }
}
