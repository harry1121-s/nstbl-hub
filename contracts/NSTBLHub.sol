pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NSTBLHUBStorage.sol";
 
contract NSTBLHub is NSTBLHUBStorage{
    using SafeERC20 for IERC20Helper;

    modifier onlyAdmin {
        require(msg.sender == admin, "HUB::NOT_ADMIN");
        _;
    }

    modifier authorizedCaller(){
        require(msg.sender == nealthyAddr, "HUB::UNAUTH");
        _;
    }

    function deposit(uint256 _amount1, uint256 _amount2, uint256 _amount3) external authorizedCaller {
        
        _checkValidDepositEvent();
        _validateEquilibrium(_amount1, _amount2, _amount3);

        IERC20Helper(usdc).safeTransferFrom(msg.sender, address(this), _amount1);
        IERC20Helper(usdt).safeTransferFrom(msg.sender, address(this), _amount2);
        IERC20Helper(dai).safeTransferFrom(msg.sender, address(this), _amount3);

        uint256 mintFee = _getMintFee(_amount1, _amount2, _amount3);
        uint256 nstblTokenAmount = _amount1 + _amount2 + _amount3;

        IERC20Helper(nstblToken).mint(msg.sender, nstblTokenAmount - mintFee);
        IERC20Helper(nstblToken).mint(nealthyAddr, mintFee);
        _reinvestAssets(_amount1*7/8);


    }

    function _checkValidDepositEvent() internal {
        for(uint256 i = 0; i<assetFeeds.length; i++){
            uint256 price = IChainlinkPriceFeed(chainLinkPriceFeed).getLatestPrice(assetFeeds[i]);
            require(price > dt, "HUB::INVALID_DEPOSIT_EVENT");
        }
    }

    function _validateEquilibrium(uint256 _amount1, uint256 _amount2, uint256 _amount3) internal {
        //TODO: check equilibrium
        require(true);
    }

    function _reinvestAssets(uint256 _amount) internal {
        IERC20Helper(usdc).approve(loanManager, _amount);
        ILoanManager(loanManager).deposit(usdc, _amount);
    }

    function _getMintFee(uint256 _amount1, uint256 _amount2, uint256 _amount3) internal view returns(uint256 mintFee) {
        uint256 totalAmount = _amount1 + _amount2 + _amount3;
        mintFee = totalAmount * 1/100;
    }

    function updateAuthorizedCaller(address _caller) public onlyAdmin {
        nealthyAddr = _caller;
    }

    function updateAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
    
    
    
}