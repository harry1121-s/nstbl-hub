pragma solidity 0.8.21;

interface IChainlinkPriceFeed {
    function getLatestPrice(address _dataFeed) external view returns (uint256 price);
    function getAverageAssetsPrice() external view returns (uint256 price);
}
