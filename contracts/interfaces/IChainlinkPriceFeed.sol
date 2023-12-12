pragma solidity 0.8.21;

interface IChainlinkPriceFeed {

    /**
     * @notice get latest price of assets
     * @return price1 price of asset 1
     * @return price2 price of asset 2
     * @return price3 price of asset 3
     */
    function getLatestPrice() external view returns (uint256 price1, uint256 price2, uint256 price3);

    /**
     * @notice get latest price of asset
     * @param dataFeed_ address of data feed
     * @return price_ price of asset
     */
    function getLatestPrice(address dataFeed_) external view returns (uint256 price_);

}
