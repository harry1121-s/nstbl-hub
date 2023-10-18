pragma solidity 0.8.21;

interface IChainlinkPriceFeed {
    function getLatestPrice() external view returns (uint256 price1, uint256 price2, uint256 price3);
    function getLatestPrice(address _dataFeed) external view returns (uint256 price);
    function getAverageAssetsPrice() external view returns (uint256 price);
}
