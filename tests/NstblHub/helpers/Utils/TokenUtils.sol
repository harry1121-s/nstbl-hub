// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { NSTBLToken } from "@nstbl-token/contracts/NSTBLToken.sol";
import { LZEndpointMock } from "@layerzerolabs/contracts/lzApp/mocks/LZEndpointMock.sol";
import { ICommonOFT } from "@layerzerolabs/contracts/token/oft/v2/interfaces/ICommonOFT.sol";

contract TokenUtils {

    NSTBLToken public localOFTToken;
    NSTBLToken public remoteOFTToken;

    LZEndpointMock public localLZEndpoint;
    LZEndpointMock public remoteLZEndpoint;


    uint16 localChainId = 1;
    uint16 remoteChainId = 2;
    string public symbol = "NSTBL";
    string public name = "NSTBL Token";
    uint8 public sharedDecimals = 5;

    event AddressBlacklistedUpdated(address indexed user, bool indexed isBlacklisted);

    // /*//////////////////////////////////////////////////////////////
    // Setup
    // //////////////////////////////////////////////////////////////*/

    // function setUp() public virtual{
    //     uint256 mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW");
    //     vm.selectFork(mainnetFork);

    //     vm.startPrank(owner);

    //     // Deploy contracts
    //     aclManager = new ACLManager();

    //     localLZEndpoint = new LZEndpointMock(localChainId);
    //     remoteLZEndpoint = new LZEndpointMock(remoteChainId);

    //     localOFTToken = new NSTBLToken(name, symbol, sharedDecimals, address(localLZEndpoint), address(aclManager));
    //     remoteOFTToken = new NSTBLToken(name, symbol, sharedDecimals, address(remoteLZEndpoint), address(aclManager));

    //     // LayerZero configurations
    //     localLZEndpoint.setDestLzEndpoint(address(remoteOFTToken), address(remoteLZEndpoint));
    //     remoteLZEndpoint.setDestLzEndpoint(address(localOFTToken), address(localLZEndpoint));

    //     bytes memory remotePath = abi.encodePacked(address(remoteOFTToken), address(localOFTToken));
    //     localOFTToken.setTrustedRemote(remoteChainId, remotePath);

    //     bytes memory localPath = abi.encodePacked(address(localOFTToken), address(remoteOFTToken));
    //     remoteOFTToken.setTrustedRemote(localChainId, localPath);

    //     localOFTToken.setAuthorizedChain(block.chainid, true);

    //     // Set authorized caller in ACLManager
    //     aclManager.setAuthorizedCallerToken(NSTBL_HUB, true);
    //     aclManager.setAuthorizedCallerToken(owner, true);
    //     localOFTToken.mint(owner, 1e8 * 1e18);
    //     aclManager.setAuthorizedCallerBlacklister(compliance, true);

    //     vm.stopPrank();
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test configurations after deployment
    // //////////////////////////////////////////////////////////////*/

    // function test_deployment() external {
    //     // Source chain checks
    //     assertEq(localOFTToken.name(), name);
    //     assertEq(localOFTToken.symbol(), symbol);
    //     assertEq(localOFTToken.decimals(), 18);
    //     assertEq(localOFTToken.sharedDecimals(), sharedDecimals);
    //     assertEq(localOFTToken.totalSupply(), 1e8 * 1e18);

    //     // Destination chain checks
    //     assertEq(remoteOFTToken.name(), name);
    //     assertEq(remoteOFTToken.symbol(), symbol);
    //     assertEq(remoteOFTToken.decimals(), 18);
    //     assertEq(remoteOFTToken.sharedDecimals(), sharedDecimals);
    //     assertEq(remoteOFTToken.totalSupply(), 0);
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test supply change functions
    // //////////////////////////////////////////////////////////////*/

    // function test_mint() external {
    //     // Mint works
    //     vm.prank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);

    //     // Mint should not work on remote since not configured
    //     vm.prank(NSTBL_HUB);
    //     vm.expectRevert("TOKEN: Mint not available");
    //     remoteOFTToken.mint(user1, 1e3 * 1e18);

    //     // Only authorized caller can mint
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: UNAUTHORIZED_CALLER");
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    // }

    // function test_mint_fuzz(uint256 amount) external {
    //     // Mint works
    //     amount = bound(amount, 0, type(uint256).max-1-1e8*1e18);
    //     vm.prank(NSTBL_HUB);
    //     localOFTToken.mint(user1, amount);
    //     assertEq(localOFTToken.balanceOf(user1), amount);

    //     // Mint should not work on remote since not configured
    //     vm.prank(NSTBL_HUB);
    //     vm.expectRevert("TOKEN: Mint not available");
    //     remoteOFTToken.mint(user1, amount);

    //     // Only authorized caller can mint
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: UNAUTHORIZED_CALLER");
    //     localOFTToken.mint(user1, amount);
    // }

    // function test_burn() external {
    //     // Setup for burn test
    //     deal(address(localOFTToken), user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);

    //     // Only authorized caller can mint
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: UNAUTHORIZED_CALLER");
    //     localOFTToken.burn(user1, 1e3 * 1e18);

    //     // Burn should not work on remote since not configured
    //     vm.prank(NSTBL_HUB);
    //     vm.expectRevert("TOKEN: Burn not available");
    //     remoteOFTToken.burn(user1, 1e3 * 1e18);

    //     // Burn works
    //     vm.prank(NSTBL_HUB);
    //     localOFTToken.burn(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 0);
    // }

    // function test_burn_fuzz(uint256 mintAmount, uint256 burnAmount) external {
    //     // Setup for burn test
    //     deal(address(localOFTToken), user1, mintAmount);
    //     assertEq(localOFTToken.balanceOf(user1), mintAmount);

    //     // Only authorized caller can mint
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: UNAUTHORIZED_CALLER");
    //     localOFTToken.burn(user1, burnAmount);

    //     // Burn works
    //     vm.prank(NSTBL_HUB);
    //     if (mintAmount >= burnAmount) {
    //         localOFTToken.burn(user1, burnAmount);
    //         assertEq(localOFTToken.balanceOf(user1), mintAmount - burnAmount);
    //     } else {
    //         vm.expectRevert("NativeOFTV2: Insufficient balance.");
    //         localOFTToken.burn(user1, burnAmount);
    //     }
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test views
    // //////////////////////////////////////////////////////////////*/

    // function test_circulatingSupply() external {
    //     vm.prank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     assertEq(localOFTToken.circulatingSupply(), 1e8 * 1e18 + 1e3 * 1e18);
    // }

    // function test_token() external {
    //     assertEq(localOFTToken.token(), address(localOFTToken));
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test transfers single chain
    // //////////////////////////////////////////////////////////////*/

    // function test_transferFrom_singleChain() external {
    //     // Setup for transferFrom test
    //     deal(address(localOFTToken), user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);

    //     // TransferFrom works
    //     vm.prank(user1);
    //     localOFTToken.approve(user3, 500 * 1e18);

    //     vm.prank(user3);
    //     localOFTToken.transferFrom(user1, user2, 500 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 500 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user2), 500 * 1e18);

    //     address stakePool = vm.addr(789);
    //     vm.startPrank(localOFTToken.owner());
    //     localOFTToken.setStakePoolAddress(stakePool);
    //     vm.stopPrank();

    //     deal(address(localOFTToken), user1, 1e3 * 1e18);

    //     vm.prank(user1);
    //     localOFTToken.approve(stakePool, 500 * 1e18);

    //     vm.prank(stakePool);
    //     localOFTToken.transferFrom(user1, stakePool, 500 * 1e18);

    //     vm.prank(user1);
    //     localOFTToken.approve(user2, 500 * 1e18);

    //     // vm.startPrank(user2);
    //     // vm.expectRevert("TOKEN: INVALID_TX");
    //     // localOFTToken.transferFrom(user1, stakePool, 500 * 1e18);
    //     // vm.stopPrank();
    // }

    // function test_transferFrom_singleChain_fuzz(uint256 mintAmount, uint256 txAmount) external {
    //     // Setup for transferFrom test
    //     deal(address(localOFTToken), user1, mintAmount);
    //     assertEq(localOFTToken.balanceOf(user1), mintAmount);

    //     // TransferFrom works
    //     vm.prank(user1);
    //     localOFTToken.approve(user3, txAmount);

    //     vm.prank(user3);
    //     if (mintAmount >= txAmount) {
    //         localOFTToken.transferFrom(user1, user2, txAmount);
    //         assertEq(localOFTToken.balanceOf(user1), mintAmount - txAmount);
    //         assertEq(localOFTToken.balanceOf(user2), txAmount);
    //     } else {
    //         vm.expectRevert();
    //         localOFTToken.transferFrom(user1, user2, txAmount);
    //     }
    // }

    // function test_transfer_singleChain() external {
    //     // Setup for transfer test
    //     deal(address(localOFTToken), user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);

    //     // Transfer works
    //     vm.prank(user1);
    //     localOFTToken.transfer(user2, 500 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 500 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user2), 500 * 1e18);

    // }

    // function test_transfer_singleChain_fuzz(uint256 mintAmount, uint256 txAmount) external {
    //     // Setup for transfer test
    //     deal(address(localOFTToken), user1, mintAmount);
    //     assertEq(localOFTToken.balanceOf(user1), mintAmount);

    //     // Transfer works
    //     vm.prank(user1);
    //     if (mintAmount >= txAmount) {
    //         localOFTToken.transfer(user2, txAmount);
    //         assertEq(localOFTToken.balanceOf(user1), mintAmount - txAmount);
    //         assertEq(localOFTToken.balanceOf(user2), txAmount);
    //     } else {
    //         vm.expectRevert();
    //         localOFTToken.transfer(user2, txAmount);
    //     }
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test transfers cross chain
    // //////////////////////////////////////////////////////////////*/

    // function test_transferTokens_crossChain() external {
    //     vm.startPrank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     vm.stopPrank();

    //     // Transfer works for same wallet address on remote chain
    //     vm.startPrank(user1);
    //     (uint256 fee,) =
    //         localOFTToken.estimateSendFee(remoteChainId, bytes32(uint256(uint160(user1))), 1e3 * 1e18, false, "");
    //     deal(user1, fee);
    //     localOFTToken.sendFrom{ value: fee }(
    //         user1,
    //         remoteChainId,
    //         bytes32(uint256(uint160(user1))),
    //         1e3 * 1e18,
    //         ICommonOFT.LzCallParams(payable(user1), address(0), "")
    //     );
    //     assertEq(localOFTToken.balanceOf(user1), 0);
    //     assertEq(remoteOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     vm.stopPrank();

    //     // Transfer works for different wallet address on remote chain
    //     vm.startPrank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     vm.stopPrank();

    //     vm.startPrank(user1);
    //     (fee,) = localOFTToken.estimateSendFee(remoteChainId, bytes32(uint256(uint160(user2))), 1e3 * 1e18, false, "");
    //     deal(user1, fee);
    //     localOFTToken.sendFrom{ value: fee }(
    //         user1,
    //         remoteChainId,
    //         bytes32(uint256(uint160(user2))),
    //         1e3 * 1e18,
    //         ICommonOFT.LzCallParams(payable(user1), address(0), "")
    //     );

    //     assertEq(localOFTToken.balanceOf(user1), 0);
    //     assertEq(remoteOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     assertEq(remoteOFTToken.balanceOf(user2), 1e3 * 1e18);
    //     vm.stopPrank();
    // }

    // function test_transferTokensFrom_crosschain() external {
    //     vm.startPrank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);
    //     vm.stopPrank();

    //     vm.prank(user1);
    //     localOFTToken.approve(user3, 1e3 * 1e18);

    //     vm.startPrank(user3);
    //     (uint256 fee,) =
    //         localOFTToken.estimateSendFee(remoteChainId, bytes32(uint256(uint160(user2))), 1e3 * 1e18, false, "");
    //     deal(user3, fee);
    //     localOFTToken.sendFrom{ value: fee }(
    //         user1,
    //         remoteChainId,
    //         bytes32(uint256(uint160(user2))),
    //         1e3 * 1e18,
    //         ICommonOFT.LzCallParams(payable(user3), address(0), "")
    //     );
    //     assertEq(localOFTToken.balanceOf(user1), 0);
    //     assertEq(remoteOFTToken.balanceOf(user2), 1e3 * 1e18);
    //     vm.stopPrank();
    // }

    // /*//////////////////////////////////////////////////////////////
    // Test ownerships and compliance
    // //////////////////////////////////////////////////////////////*/

    // function test_setAuthorizedChain_fuzz(uint256 chainId, bool isAuthorized) external {
    //     vm.prank(owner);
    //     localOFTToken.setAuthorizedChain(chainId, isAuthorized);
    //     assertEq(localOFTToken.authorizedChain(chainId), isAuthorized);
    // }

    // function test_blacklister() external {
    //     // Setup for blacklist test
    //     vm.prank(NSTBL_HUB);
    //     localOFTToken.mint(user1, 1e3 * 1e18);
    //     assertEq(localOFTToken.balanceOf(user1), 1e3 * 1e18);

    //     // Only blacklister can blacklist
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: UNAUTHORIZED_BLACKLISTER");
    //     localOFTToken.setIsBlacklisted(user1, true);

    //     // Blacklist works
    //     vm.prank(compliance);
    //     vm.expectEmit(true, true, false, false);
    //     emit AddressBlacklistedUpdated(user1, true);
    //     localOFTToken.setIsBlacklisted(user1, true);

    //     // Transfer should not work if `from` address is blacklisted
    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: BLACKLISTED_FROM");
    //     localOFTToken.transfer(user2, 500 * 1e18);

    //     // Transfer should not work if `to` address is blacklisted
    //     vm.startPrank(compliance);
    //     localOFTToken.setIsBlacklisted(user1, false);
    //     localOFTToken.setIsBlacklisted(user2, true);
    //     vm.stopPrank();

    //     vm.prank(user1);
    //     vm.expectRevert("TOKEN: BLACKLISTED_TO");
    //     localOFTToken.transfer(user2, 500 * 1e18);

    //     // TransferFrom should not work if spender is blacklisted
    //     vm.startPrank(compliance);
    //     localOFTToken.setIsBlacklisted(user2, false);
    //     localOFTToken.setIsBlacklisted(user3, true);
    //     vm.stopPrank();

    //     vm.prank(user1);
    //     localOFTToken.approve(user3, 500 * 1e18);

    //     vm.prank(user3);
    //     vm.expectRevert("TOKEN: BLACKLISTED_SPENDER");
    //     localOFTToken.transferFrom(user1, user2, 500 * 1e18);

    //     // TransferFrom should not work if `to` address is blacklisted
    //     vm.prank(user1);
    //     localOFTToken.approve(user2, 500 * 1e18);
    //     vm.prank(user2);
    //     vm.expectRevert("TOKEN: BLACKLISTED_TO");
    //     localOFTToken.transferFrom(user1, user3, 500 * 1e18);

    //     // TransferFrom should not work if `from` address is blacklisted
    //     vm.startPrank(compliance);
    //     localOFTToken.setIsBlacklisted(user1, true);
    //     localOFTToken.setIsBlacklisted(user2, false);
    //     localOFTToken.setIsBlacklisted(user3, false);
    //     vm.stopPrank();

    //     vm.prank(user1);
    //     localOFTToken.approve(user2, 500 * 1e18);
    //     vm.prank(user2);
    //     vm.expectRevert("TOKEN: BLACKLISTED_FROM");
    //     localOFTToken.transferFrom(user1, user3, 500 * 1e18);
    // }
}
