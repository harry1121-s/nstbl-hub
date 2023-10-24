pragma solidity 0.8.21;

import { eqLogic } from "../../contracts/equilibriumLogic.sol";

contract eqLogicInternal is eqLogic {
    constructor(address _priceFeed, address _loanManager, address _nstblToken, uint256 _dt, uint256 _eqTh)
        eqLogic(_priceFeed, _loanManager, _nstblToken, _dt, _eqTh)
    { }

    function calculateEquilibrium(uint256 cr1, uint256 cr2, uint256 cr3) external view returns (uint256 _eq) {
        _eq = _calcEq(cr1, cr2, cr3);
    }

    function validateSystemAllocation(uint256 _usdtAmt, uint256 daiAmt) external view returns(uint256 _a1, uint256 _a2, uint256 _a3) {
        (_a1, _a2, _a3) = _validateSystemAllocation(_usdtAmt, daiAmt);
    }

    function getSystemAllocation() external view returns (uint256 _a1, uint256 _a2, uint256 _a3) {
        (_a1, _a2, _a3) = _getSystemAllocation();
    }

    function getAssetBalances() external view returns(uint256[] memory) {
        return _getAssetBalances();
    }
}
