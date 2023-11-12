pragma solidity 0.8.21;

interface IStakePool {
    /*//////////////////////////////////////////////////////////////
    EVENTS
    //////////////////////////////////////////////////////////////*/

    event Stake(address indexed user, uint256 stakeAmount, uint256 poolDebt);
    event Unstake(address indexed user, uint256 tokensAvailable);

    struct StakerInfo {
        uint256 amount;
        uint256 poolDebt;
        uint256 stakeTimeStamp;
        uint256 epochId;
        uint256 lpTokens;
    }

    function setATVL(address atvl) external;
    function updatePoolFromHub(bool redeem, uint256 stablesReceived, uint256 depositAmount) external;
    function updatePool() external;
    function updateMaturityValue() external;
    function withdrawUnclaimedRewards() external;
    function getUserAvailableTokens(address _user, uint8 _trancheId) external view returns(uint256 availableTokens);
    function burnNSTBL(uint256 amount) external;
    function stake(address user, uint256 stakeAmount, uint8 trancheId, address destinationAddress) external;
    function unstake(address user, uint8 trancheId, bool depeg, address lpOwner) external returns(uint256 tokensUnstaked);
    function getStakerInfo(address user, uint8 trancheId) external view returns(uint256, uint256, uint256, uint256);
    function transferATVLYield() external;
    function getVersion() external returns(uint256);

}
