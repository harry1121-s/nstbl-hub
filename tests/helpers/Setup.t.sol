// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

// import { Test, console } from "forge-std/Test.sol";
import { StakePoolMock } from "../../contracts/mocks/StakePool/StakePoolMock.sol";
import { NSTBLTokenMock } from "../../contracts/mocks/NSTBLTokenMock.sol";
import { ChainLinkPriceFeed } from "../../contracts/chainlink/ChainlinkPriceFeed.sol";
import { NSTBLHub } from "../../contracts/NSTBLHub.sol";
import { Utils } from "./utils.sol"; 
// import { IERC20Helper } from "../../contracts/interfaces/IERC20Helper.sol";

contract BaseTest is Utils {

    StakePoolMock public stakePool;
    ChainLinkPriceFeed public priceFeed;
    NSTBLTokenMock public nstblToken;
    NSTBLHub public nstblHub;


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
        stakePool.configurePool(250, 30 days, 100);
        stakePool.configurePool(350, 60 days, 100);
        stakePool.configurePool(400, 90 days, 100);
        nstblHub.setSystemParams(dt, ub, lb);
        vm.stopPrank();


    }

}