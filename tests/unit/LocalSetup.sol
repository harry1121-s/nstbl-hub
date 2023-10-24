// pragma solidity 0.8.21;

// import { Test, console } from "forge-std/Test.sol";
// import { MockV3Aggregator } from "../../modules/chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";


// contract eqLogicInternalTest is Test {
//     address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
//     MockV3Aggregator public usdcPriceFeedMock;
//     MockV3Aggregator public usdtPriceFeedMock;
//     MockV3Aggregator public daiPriceFeedMock;

//     function setUp() public {
//         vm.etch(DAI, code);
//     }

//     function test_name() external view {
//         string memory name;
//         (,bytes memory data) = address(DAI).staticcall(abi.encodeWithSignature("symbol()"));
//         (name) = abi.decode(data, (string));
//         console.log("name: ", name);
//     }

// }