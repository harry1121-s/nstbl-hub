// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { StakePoolMock } from "../../contracts/mocks/StakePool/StakePoolMock.sol";
import { NSTBLTokenMock } from "../../contracts/mocks/NSTBLTokenMock.sol";
import { ChainLinkPriceFeed } from "../../contracts/chainlink/ChainlinkPriceFeed.sol";
import { NSTBLHub, IERC20Helper } from "../../contracts/NSTBLHub.sol";
// import { IERC20Helper } from "../../contracts/interfaces/IERC20Helper.sol";

contract BaseTest is Test {
    using SafeERC20 for IERC20Helper;

    StakePoolMock public stakePool;
    ChainLinkPriceFeed public priceFeed;
    NSTBLTokenMock public nstblToken;
    NSTBLHub public nstblHub;

    address public admin = address(123);
    address public nealthyAddr = address(456);
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);


    function setUp() public virtual {

        uint256 mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW");
        vm.selectFork(mainnetFork);
        vm.startPrank(admin);
        priceFeed = new ChainLinkPriceFeed();
        nstblToken = new NSTBLTokenMock("NSTBL Token", "NSTBL", admin);
        
        stakePool = new StakePoolMock(
            admin,
            address(nstblToken)
        );
        nstblHub = new NSTBLHub(
            nealthyAddr,
            address(nstblToken),
            address(stakePool),
            address(priceFeed),
            admin
        );
        nstblToken.setStakePool(address(stakePool));
        stakePool.init(address(nstblHub));
        vm.stopPrank();
    }

}