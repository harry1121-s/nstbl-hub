// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/**
 * @dev External interface of NSTBLToken used by different contracts in the nSTBL protocol
 */
interface INSTBLToken {
    /**
     * @dev Emitted when `_user` is blacklisted or unblacklisted
     * @param _user The address of the user whose blacklist status is updated
     * @param _isBlacklisted The blacklist status of the user
     */
    event AddressBlacklistedUpdated(address indexed _user, bool indexed _isBlacklisted);

    /**
     * @dev Emitted when funds are removed from blacklisted wallet
     * @param _user The address of the user whose blacklist status is updated
     * @param _to The address of the wallet receiving the tokens
     * @param _amount The amount of tokens transferred from blacklisted wallet
     */
    event BlacklistTokensTransferred(address indexed _user, address indexed _to, uint256 _amount);

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`
     * @param dstAddress The address of the user receiving the tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address dstAddress, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `user`, reducing the total supply
     * @param user The address of the user whose tokens are burned
     */
    function burn(address user, uint256 amount) external;

    /**
     * @dev Used by hub to send to or receive from the stakepool
     * @param from The address of the user or pool to send from
     * @param to The address of the user or pool to send to
     */
    function sendOrReturnPool(address from, address to, uint256 amount) external;
}
