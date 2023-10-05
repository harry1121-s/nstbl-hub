// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.21;

// import { Test, console } from "forge-std/Test.sol";
// import {PriceFeed} from "../contracts/ChainlinkPriceFeed.sol";

// contract TestPriceFeed is Test {
//     address public USDT_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
//     address public USDC_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
//     address public DAI_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

//     PriceFeed public feed;

//     uint256 mainnetFork;

//     function setUp() public{
//         mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW");
//         vm.selectFork(mainnetFork);

//         feed = new PriceFeed(USDT_FEED);
//     }

//     function test_fetchUSDT_price() external {
//         int price = feed.getLatestPrice();
//         console.logInt(price);
//     }

//     function test_fetchUSDC_price() external {
//         feed = new PriceFeed(USDC_FEED);
//         int price = feed.getLatestPrice();
//         console.logInt(price);
//     }

//     function test_fetchDAI_price() external {
//         feed = new PriceFeed(DAI_FEED);
//         int price = feed.getLatestPrice();
//         console.logInt(price);
//     }

//     function test_fetchAverageAssetsPrice() external {
//         int price = feed.getAverageAssetsPrice();
//         console.logInt(price);
//     }


// }