pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLinkPriceFeed {
    AggregatorV3Interface public dataFeed;
    address public USDC_FEED;
    address public USDT_FEED;
    address public DAI_FEED;

    constructor(address _usdcFeed, address _usdtFeed, address _daiFeed) {
        USDC_FEED = _usdcFeed;
        USDT_FEED = _usdtFeed;
        DAI_FEED = _daiFeed;
    }

    function getLatestPrice() external view returns (uint256, uint256, uint256) {
        (, int256 p1,,,) = AggregatorV3Interface(USDC_FEED).latestRoundData();
        (, int256 p2,,,) = AggregatorV3Interface(USDT_FEED).latestRoundData();
        (, int256 p3,,,) = AggregatorV3Interface(DAI_FEED).latestRoundData();
        return (uint256(p1), uint256(p2), uint256(p3));
    }

    function getLatestPrice(address _dataFeed) external view returns (uint256) {
        (, int256 p,,,) = AggregatorV3Interface(_dataFeed).latestRoundData();
        return uint256(p);
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
