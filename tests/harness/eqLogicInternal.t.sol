// pragma solidity 0.8.21;

// import { Test, console } from "forge-std/Test.sol";
// import "./eqLogicInternal.sol";

// contract eqLogicInternalTest is Test {
//     eqLogicInternal eqLogic;

//     function setUp() public{
//         eqLogic = new eqLogicInternal(address(this), address(this), address(this), 1, 1);
//     }

//     function test_calcEq() public {
//         uint256 eq = eqLogic.calculateEquilibrium(1, 1, 1);
//         assertTrue(eq == 1, "eq should be 1");
//     }

//     function test_getSystemAllocation() public {
//         (uint256 a1, uint256 a2, uint256 a3) = eqLogic.getSystemAllocation();
//         assertTrue(a1 == 0, "a1 should be 0");
//         assertTrue(a2 == 0, "a2 should be 0");
//         assertTrue(a3 == 0, "a3 should be 0");
//     }

//     function test_validateSystemAllocation() public {
//         (uint256 a1, uint256 a2, uint256 a3) = eqLogic.validateSystemAllocation(1, 1);
//         assertTrue(a1 == 0, "a1 should be 0");
//         assertTrue(a2 == 0, "a2 should be 0");
//         assertTrue(a3 == 0, "a3 should be 0");
//     }
// }