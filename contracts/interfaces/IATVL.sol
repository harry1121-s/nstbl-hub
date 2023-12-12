pragma solidity 0.8.21;

interface IATVL {
    /**
     * @notice only authorized callers can call this function
     * @dev burn NSTBL tokens
     * @param _burnAmount amount of NSTBL to burn
     */
    function burnNstbl(uint256 _burnAmount) external;

    function init(address, uint256) external;
}
