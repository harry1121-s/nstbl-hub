pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC20Helper.sol";

contract Atvl {
    mapping(address => bool) public authorizedCallers;
    address public _admin;
    address public nstblToken;
    uint256 public totalNstblReceived;
    uint256 public totalNstblBurned;
    uint256 public pendingNstblBurn;

    modifier authorizedCaller() {
        require(authorizedCallers[msg.sender], "ATVL::NOT AUTHORIZED");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ATVL::NOT ADMIN");
        _;
    }

    constructor(address _admin_) {
        _admin = _admin_;
    }

    function init(address _nstblToken) external onlyAdmin {
        nstblToken = _nstblToken;
    }

    function setAuthorizedCaller(address _caller, bool _isAuthorized) external onlyAdmin {
        authorizedCallers[_caller] = _isAuthorized;
    }

    function burnNstbl(uint256 _burnAmount) external authorizedCaller {
        
        uint256 burnAmount = _burnAmount + pendingNstblBurn <= IERC20Helper(nstblToken).balanceOf(address(this))
            ? _burnAmount + pendingNstblBurn
            : IERC20Helper(nstblToken).balanceOf(address(this));
        totalNstblBurned += burnAmount;
        pendingNstblBurn = _burnAmount + pendingNstblBurn - burnAmount;
        IERC20Helper(nstblToken).burn(address(this), burnAmount);

    }

    function checkDeployedATVL() external view returns (uint256) {
        return IERC20Helper(nstblToken).balanceOf(address(this));
    }

}
