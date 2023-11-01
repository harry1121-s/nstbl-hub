pragma solidity 0.8.21;

import { NSTBLHub } from "../../contracts/NSTBLHub.sol";

contract NSTBLHubInternal is NSTBLHub {

    constructor( 
        address _nealthyAddr,
        address _nstblToken,
        address _stakePool,
        address _chainLinkPriceFeed,
        address _atvl,
        address _admin,
        address _loanManager,
        uint256 _eqTh) NSTBLHub(_nealthyAddr, _nstblToken, _stakePool, _chainLinkPriceFeed, _atvl, _admin, _loanManager, _eqTh) { }
    function getSortedAssetsWithPrice()
        external
        view
        returns (address[] memory _assets, uint256[] memory _assetsPrice){
            (_assets, _assetsPrice) = _getSortedAssetsWithPrice();
        }
}
