pragma solidity 0.8.21;

import { NSTBLHub } from "../../contracts/NSTBLHub.sol";

contract NSTBLHubInternal is NSTBLHub {
    constructor(
        address _nstblToken,
        address _stakePool,
        address _chainLinkPriceFeed,
        address _atvl,
        address _loanManager,
        address _aclManager,
        uint256 _eqTh
    ) NSTBLHub(_nstblToken, _stakePool, _chainLinkPriceFeed, _atvl, _loanManager, _aclManager, _eqTh) { }

    function getSortedAssetsWithPrice()
        external
        view
        returns (address[] memory _assets, uint256[] memory _assetsPrice)
    {
        (_assets, _assetsPrice) = _getSortedAssetsWithPrice();
    }
}
