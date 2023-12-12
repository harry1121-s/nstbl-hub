pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLinkPriceFeed {
    AggregatorV3Interface public dataFeed;
    address public USDC_FEED;
    address public USDT_FEED;
    address public DAI_FEED;

    constructor(address usdcFeed_, address usdtFeed_, address daiFeed_) {
        USDC_FEED = usdcFeed_;
        USDT_FEED = usdtFeed_;
        DAI_FEED = daiFeed_;
    }

    /**
     * @notice get latest price of assets
     * @return price1_ price of asset 1
     * @return price2_ price of asset 2
     * @return price3_ price of asset 3
     */
    function getLatestPrice() external view returns (uint256 price1_, uint256 price2_, uint256 price3_) {
        (, int256 p1,,,) = AggregatorV3Interface(USDC_FEED).latestRoundData();
        (, int256 p2,,,) = AggregatorV3Interface(USDT_FEED).latestRoundData();
        (, int256 p3,,,) = AggregatorV3Interface(DAI_FEED).latestRoundData();
        (price1_, price2_, price3_) = (uint256(p1), uint256(p2), uint256(p3));
    }

    /**
     * @notice get latest price of asset
     * @param dataFeed_ address of data feed
     * @return price_ price of asset
     */
    function getLatestPrice(address dataFeed_) external view returns (uint256 price_) {
        (, int256 p,,,) = AggregatorV3Interface(dataFeed_).latestRoundData();
        price_ = uint256(p);
    }
}
