pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IACLManager } from "@nstbl-acl-manager/contracts/IACLManager.sol";
import "./interfaces/IERC20Helper.sol";
import "./interfaces/IATVL.sol";

contract ATVL is IATVL {
    using SafeERC20 for IERC20Helper;

    mapping(address => bool) public authorizedCallers;
    address public aclManager;
    address public nstblToken;
    uint256 public totalNstblReceived;
    uint256 public totalNstblBurned;
    uint256 public pendingNstblBurn;
    uint256 public atvlThreshold;

    /*//////////////////////////////////////////////////////////////
    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier authorizedCaller() {
        require(authorizedCallers[msg.sender], "ATVL::NOT AUTHORIZED");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == IACLManager(aclManager).admin(), "HUB::NOT_ADMIN");
        _;
    }

    /*//////////////////////////////////////////////////////////////
    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address aclManager_) {
        require(aclManager_ != address(0), "ATVL: invalid Address");
        aclManager = aclManager_;
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN SETTERS
    //////////////////////////////////////////////////////////////*/

    function init(address nstblToken_, uint256 atvlThreshold_) external onlyAdmin {
        require(nstblToken_ != address(0), "ATVL: invalid Address");
        require(atvlThreshold_ > 0, "ATVL: invalid Threshold");
        nstblToken = nstblToken_;
        atvlThreshold = atvlThreshold_;
    }

    function setAuthorizedCaller(address caller_, bool isAuthorized_) external onlyAdmin {
        authorizedCallers[caller_] = isAuthorized_;
    }

    /*//////////////////////////////////////////////////////////////
    DEPEG BURNS
    //////////////////////////////////////////////////////////////*/

    function burnNstbl(uint256 burnAmount_) external authorizedCaller {
        uint256 burnAmount = burnAmount_ + pendingNstblBurn <= IERC20Helper(nstblToken).balanceOf(address(this))
            ? burnAmount_ + pendingNstblBurn
            : IERC20Helper(nstblToken).balanceOf(address(this));
        totalNstblBurned += burnAmount;
        pendingNstblBurn = burnAmount_ + pendingNstblBurn - burnAmount;
        IERC20Helper(nstblToken).burn(address(this), burnAmount);
    }

    /*//////////////////////////////////////////////////////////////
    SKIM PROFITS
    //////////////////////////////////////////////////////////////*/

    function skimProfits(address destinationAddress_) external onlyAdmin returns (uint256 skimAmount_) {
        uint256 atvlBalance = IERC20Helper(nstblToken).balanceOf(address(this));
        uint256 thresholdBalance = atvlThreshold * IERC20Helper(nstblToken).totalSupply() / 1e5;
        skimAmount_ = atvlBalance > thresholdBalance ? (atvlBalance - thresholdBalance) : 0;
        IERC20Helper(nstblToken).safeTransfer(destinationAddress_, skimAmount_);
    }
}
