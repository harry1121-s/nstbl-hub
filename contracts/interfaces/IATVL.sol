pragma solidity 0.8.21;

interface IATVL {
    

    /**
     * @notice only admin can call this function
     * @dev initializes ATVL contract
     * @param nstblToken_ address of NSTBL Token
     * @param atvlThreshold_ ATVL threshold percent
     */
    function init(address nstblToken_, uint256 atvlThreshold_) external;

     /**
     * @notice only admin can call this function
     * @dev Sets authorized callers for ATVL contract
     * @param caller_ address of the caller
     * @param isAuthorized_ bool value
     */
    function setAuthorizedCaller(address caller_, bool isAuthorized_) external;

    /**
     * @notice only authorized callers can call this function
     * @dev burn NSTBL tokens
     * @param _burnAmount amount of NSTBL to burn
     */
    function burnNstbl(uint256 _burnAmount) external;

    /**
     * @notice only admin can call this function
     * @dev Skim profits from ATVL and transfer the NSTBL tokens to a designated Address
     * @param destinationAddress_ Address to receive the skimmed NSTBL tokens
     * @return skimAmount_ Amount of tokens skimmed from ATVL
     */
    function skimProfits(address destinationAddress_) external returns(uint256 skimAmount_);

}
