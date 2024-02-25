pragma solidity 0.8.21;

interface INSTBLHub {
    /**
     * @dev Emitted when NSTBLHub contract is initialized
     * @param nstblToken_ Address of NSTBL Token
     * @param stakePool_ Address of Stake Pool
     * @param chainLinkPriceFeed_ Address of ChainLink Price Feed contract
     * @param atvl_ Address of ATVL
     * @param loanManager_ Address of Loan Manager
     * @param aclManager_ Address of ACL Manager
     * @param eqTh_ Equilibrium Threshold Value
     */
    event InitializedHub(
        address nstblToken_,
        address stakePool_,
        address chainLinkPriceFeed_,
        address atvl_,
        address loanManager_,
        address aclManager_,
        uint256 eqTh_
    );

    /**
     * @dev Emitted when stable tokens are deposited and NSTBL token is minted
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @param tBillAmt_ The amount of TBill to be deposited
     * @param nstblMinted_ NSTBL tokens minted
     * @param receiver_ Address receiving minted NSTBL
     */
    event Deposited(
        uint256 usdcAmt_,
        uint256 usdtAmt_,
        uint256 daiAmt_,
        uint256 tBillAmt_,
        uint256 nstblMinted_,
        address indexed receiver_
    );

    /**
     * @dev Emitted when NSTBL tokens are requested for redemption 
     * @param amount_ The amount of NSTBL to be redeemed
     * @param tBillRedeemAmount_ The amount of TBills(in USDC) to be liquidated
     */
    event RedemptionRequested(uint256 amount_, uint256 tBillRedeemAmount_);
    
    /**
     * @dev Emitted when NSTBL tokens are redeemed 
     * @param dstAddress_ Address receiving redeemed stables
     * @param nstblDebt_ Total number of NSTBL Tokens requested for redemption
     * @param redeemAmount_ Total number of NSTBL Tokens redeemed
     * @param usdcAmount_ amount of USDC tokens transferred
     * @param usdtAmount_ amount of USDT tokens transferred
     * @param daiAmount_ amount of DAI tokens transferred
     */
    event NSTBLRedeemed(address indexed dstAddress_, uint256 nstblDebt_, uint256 redeemAmount_, uint256 usdcAmount_, uint256 usdtAmount_, uint256 daiAmount_);
    
    /**
     * @dev Emitted when NSTBL tokens are redeemed 
     * @param totalBurnAmount_ Total number of NSTBL Tokens burned
     * @param atvlBurnAmount_ Total number of NSTBL Tokens burned from ATVL
     * @param spBurnAmount_ Total number of NSTBL Tokens burned from Stake Pool
     * @param excessUSDCAmount_ excess amount of USDC tokens transferred
     * @param excessUSDTAmount_ excess amount of USDT tokens transferred
     * @param excessDAIAmount_ excess amount of DAI tokens transferred
     */
    event NSTBLBurnParams(uint256 totalBurnAmount_, uint256 atvlBurnAmount_, uint256 spBurnAmount_, uint256 excessUSDCAmount_, uint256 excessUSDTAmount_, uint256 excessDAIAmount_);
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
    function validateDepositEquilibrium(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_)
        external
        view
        returns (bool result_);

    /**
     * @dev Calculates the amount of tokens that will be deposited according to the equilibrium ratio
     * @param usdcAmt_ The amount of USDC to be deposited
     * @param usdtAmt_ The amount of USDT to be deposited
     * @param daiAmt_ The amount of DAI to be deposited
     * @param destAddress_ The address of the receiving account
     */
    function deposit(uint256 usdcAmt_, uint256 usdtAmt_, uint256 daiAmt_, address destAddress_) external;

    /**
     * @dev Function to request redemption of NSTBL tokens
     * @param amount_ The amount of NSTBL tokens to be redeemed
     */
    function requestRedemption(uint256 amount_) external;
    /**
     * @dev Function to process the redemption of requested NSTBL tokens 
     * @param dstAddress_ The address receving funds
     * @notice Only the amount of tokens requested for redemption are considered during processing
     */
    function processRedemption(address dstAddress_) external;

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
    function setSystemParams(uint256 dt_, uint256 ub_, uint256 lb_, uint256 tBillPercent_, uint256 eqTh_) external;

    /**
     * @dev The process to redeem the TBills from loan manager and update the balance
     * @return usdcRedeemed_ The amount of USDC redeemed
     */
    function processTBillWithdraw() external returns (uint256 usdcRedeemed_);
}
