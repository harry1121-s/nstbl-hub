pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceFeed {
    AggregatorV3Interface public dataFeed;
    address public USDT_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public USDC_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public DAI_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

    constructor(address _dataFeed) {
        dataFeed = AggregatorV3Interface(_dataFeed);
    }

    function getLatestPrice(address _dataFeed) external view returns (int256 price) {
        (, price,,,) = AggregatorV3Interface(_dataFeed).latestRoundData();
        return (price);
    }

    function getDecimals() external view returns (uint256 decimals) {
        decimals = dataFeed.decimals();
    }

    function getAverageAssetsPrice() external view returns (int256 price) {
        (, int256 price1,,,) = AggregatorV3Interface(USDT_FEED).latestRoundData();
        (, int256 price2,,,) = AggregatorV3Interface(USDC_FEED).latestRoundData();
        (, int256 price3,,,) = AggregatorV3Interface(DAI_FEED).latestRoundData();
        price = (price1 + price2 + price3) / 3;
    }
}
