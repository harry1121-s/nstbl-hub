pragma solidity 0.8.21;

interface INSTBLHub {

    /**
     * @dev Emitted when stable tokens are deposited and NSTBL token is minted
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @param tBillAmt_ The amount of TBill to be deposited
     * @param nstblMinted_ NSTBL tokens minted
     * @param receiver_ Address receiving minted NSTBL
     */
    event Deposited(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_, uint256 tBillAmt_, uint256 nstblMinted_, address indexed receiver_);

    /**
     * @dev Emitted when NSTBL tokens are redeemed in a non-depeg scenario
     * @param amount_ The amount of NSTBL to be redeemed
     * @param destAddress_ Address receiving stable tokens
     */
    event RedeemedNormal(uint256 amount_, address indexed destAddress_);

    /**
     * @dev Emitted when NSTBL tokens are redeemed in a depeg scenario
     * @param amount_ The amount of NSTBL to be redeemed
     * @param destAddress_ Address receiving stable tokens
     * @param burnAmt_ NSTBL tokens burnt from ATVL
     * @param stakePoolBurnAmt_ NSTBL tokens burnt from Stake Pool
     */
    event RedeemedDepeg(uint256 amount_, address indexed destAddress_, uint256 burnAmt_, uint256 stakePoolBurnAmt_);

    /**
     * @dev Emitted when NSTBL tokens are unstaked in a depeg scenario
     * @param destAddress_ Address receiving unstaked NSTBL and redeemed stables
     * @param unstakeBurnAmt_ users's NSTBL tokens burnt for redemption
     * @param burnAmt_ NSTBL tokens burnt from ATVL
     */
    event UnstakedAndRedeemed(address indexed destAddress_, uint256 unstakeBurnAmt_, uint256 burnAmt_);
    
    /**
     * @dev Calculates the amount of USDC, USDT and DAI that will be deposited
     * @param depositAmount_ The amount of tokens to be deposited
     * @return amt1_ The amount of USDC to be deposited
     * @return amt2_ The amount of USDT to be deposited
     * @return amt3_ The amount of DAI to be deposited
     * @return tBillAmt_ The amount of TBill to be deposited
     */
    function previewDeposit(uint256 depositAmount_)
        external
        view
        returns (uint256 amt1_, uint256 amt2_, uint256 amt3_, uint256 tBillAmt_);

    /**
     * @dev Calculates the amount of USDC, USDT and DAI that will be deposited
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @return result_ boolean value indicating the deposit input amounts will maintain equilbrium or not
     */
    function validateDepositEquilibrium(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_) external view returns (bool result_);

    /**
     * @dev Calculates the amount of tokens that will be deposited according to the equilibrium ratio
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     */
    function deposit(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_) external;

    /**
     * @dev Calculates the amount of tokens that will be redeemed
     * @param amount_ The amount of tokens to be redeemed
     * @param destinationAddress_ The address of the receiving account
     */
    function redeem(uint256 amount_, address destinationAddress_) external;

    /**
     * @dev The amount of tokens will be unstaked
     * @param user_ The address of the user
     * @param trancheId_ The tranche id of the user
     * @param destinationAddress_ The address of the receiving account
     */
    function unstake(address user_, uint8 trancheId_, address destinationAddress_) external;

    /**
     * @dev The amount of tokens will get staked
     * @param user_ The address of the user
     * @param amount_ The amount of tokens to be staked
     * @param trancheId_ The tranche id of the user
     */
    function stake(address user_, uint256 amount_, uint8 trancheId_) external;

    /**
     * @dev The asset feeds will get updated
     * @param assetFeeds_ The array of asset feeds
     */
    function updateAssetFeeds(address[3] memory assetFeeds_) external;

    /**
     * @dev The system parameters will get updated
     * @param dt_ The dt value is set
     * @param ub_ The upper bound value is set
     * @param lb_ The lower bound value is set
     * @param tBillPercent_ The tBill assets percent
     * @param eqTh_ The equilibrium threshold
     */
    function setSystemParams(uint256 dt_, uint256 ub_, uint256 lb_, uint256 tBillPercent_, uint256 eqTh_)
        external;

    /**
     * @dev The process to redeem the TBills from loan manager and update the balance
     * @return usdcRedeemed_ The amount of USDC redeemed
     */
    function processTBillWithdraw() external returns (uint256 usdcRedeemed_);

}
