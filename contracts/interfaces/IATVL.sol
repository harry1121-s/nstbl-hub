pragma solidity 0.8.21;

interface IATVL {
    function burnNstbl(uint256 _burnAmount) external;
    function init(address, uint256) external;
}
