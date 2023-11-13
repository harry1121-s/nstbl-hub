pragma solidity 0.8.21;

interface INSTBLHub {
    /**
     * @dev Calculates the amount of USDC, USDT and DAI that will be deposited
     * @param _depositAmount The amount of tokens to be deposited 
     * @return _amt1 The amount of USDC to be deposited
     * @return _amt2 The amount of USDT to be deposited
     * @return _amt3 The amount of DAI to be deposited
     * @return _tBillAmt The amount of TBill to be deposited
     */
    function previewDeposit(uint256 _depositAmount) external view returns (uint256 _amt1, uint256 _amt2, uint256 _amt3, uint256 _tBillAmt);

    /**
     * @dev Calculates the amount of tokens that will be deposited according to the equilibrium ratio
     * @param _usdcAmt The amount of USDC to be deposited
     * @param _usdtAmt The amount of USDT to be deposited
     * @param _daiAmt The amount of DAI to be deposited
     */
    function deposit(uint256 _usdcAmt, uint256 _usdtAmt, uint256 _daiAmt) external;

    /**
     * @dev Calculates the amount of tokens that will be redeemed
     * @param _amount The amount of tokens to be redeemed
     * @param _user The address of the user
     */
    function redeem(uint256 _amount, address _user) external;

    /**
     * @dev The amount of tokens will be unstaked
     * @param _user The address of the user
     * @param _trancheId The tranche id of the user
     * @param _lpOwner The address of the LP owner 
     */
    function unstake(address _user, uint8 _trancheId, address _lpOwner) external;

    /**
     * @dev The amount of tokens will get staked
     * @param _user The address of the user
     * @param _amount The amount of tokens to be staked
     * @param _trancheId The tranche id of the user
     * @param _destAddress The address of the destination where the staked tokens will be stored
     */
    function stake(address _user, uint256 _amount, uint8 _trancheId, address _destAddress) external;
    
    /** 
     * @dev The asset will get allocated
     * @param _asset The address of the asset
     * @param _allocation The allocation amount of the asset
    */
    function updateAssetAllocation(address _asset, uint256 _allocation) external;

    /**
     * @dev The asset feeds will get updated
     * @param _assetFeeds The array of asset feeds
     */
    function updateAssetFeeds(address[3] memory _assetFeeds) external;

    /**
     * @dev The system parameters will get updated
     * @param _dt The dt value is set
     * @param _ub The upper bound value is set
     * @param _lb The lower bound value is set
     * @param _liquidPercent The liquid percent value is set
     * @param _tBillPercent The tBill percent value is set
     */
    function setSystemParams(uint256 _dt, uint256 _ub, uint256 _lb, uint256 _liquidPercent, uint256 _tBillPercent) external;

    /**
     * @dev The process to redeem the TBills and update the balance
     * @return usdcRedeemed The amount of USDC redeemed
     */
    function processTBillWithdraw() external  returns(uint256 usdcRedeemed); 

    /**
     * @dev The process to retrieve the funds from the contract
     * @param _asset The address of the asset
     * @param _amount The amount of the asset to be retrieved
     */
    function retrieveFunds(address _asset, uint256 _amount) external;

}