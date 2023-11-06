// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ACLManager } from "@nstbl-acl-manager/contracts/ACLManager.sol";

contract ACLManagerUtils{
    ACLManager aclManager;

    

    /*//////////////////////////////////////////////////////////////
    Events
    //////////////////////////////////////////////////////////////*/

    // ACLManager events
    event Paused(address account);
    event Unpaused(address account);
    event AuthorizedCallerHubUpdated(address indexed caller, bool indexed isAuthorized);
    event AuthorizedCallerStakePoolUpdated(address indexed caller, bool indexed isAuthorized);
    event AuthorizedCallerTokenUpdated(address indexed caller, bool indexed isAuthorized);
    event AuthorizedCallerLoanManagerUpdated(address indexed caller, bool indexed isAuthorized);
    event AuthorizedCallerBlacklisterUpdated(address indexed caller, bool indexed isAuthorized);

    // Ownable2Step events
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
    Setup
    //////////////////////////////////////////////////////////////*/

//     function setUp() public {
//         vm.prank(owner);
//         aclManager = new ACLManager();
//     }

//     /*//////////////////////////////////////////////////////////////
//     Only owner setters 
//     //////////////////////////////////////////////////////////////*/

//     function testDeploymentState() public {
//         assertEq(aclManager.owner(), owner);
//         assertFalse(aclManager.isPaused());
//     }

//     function test_ownership() public {
//         // Current owner set correctly
//         assertEq(aclManager.owner(), owner);

//         //admin set correctly
//         assertEq(aclManager.admin(), owner);

//         // Only current owner can transfer ownership
//         vm.expectRevert();
//         aclManager.transferOwnership(vm.addr(2));

//         // Initiate Ownership transfer works
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit OwnershipTransferStarted(owner, vm.addr(2));
//         aclManager.transferOwnership(vm.addr(2));
//         assertEq(aclManager.pendingOwner(), vm.addr(2));

//         // Accept Ownership works
//         vm.prank(vm.addr(2));
//         vm.expectEmit(true, true, false, false);
//         emit OwnershipTransferred(owner, vm.addr(2));
//         aclManager.acceptOwnership();
//         assertEq(aclManager.owner(), vm.addr(2));
//     }

//     function test_setAuthorizedCallerHub() public {
//         // Only owner can set authorized caller
//         vm.expectRevert();
//         aclManager.setAuthorizedCallerHub(vm.addr(2), true);

//         // New caller cannot be the zero address
//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: caller is the zero address");
//         aclManager.setAuthorizedCallerHub(address(0), true);

//         // Set authorized caller works for true
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerHubUpdated(vm.addr(2), true);
//         aclManager.setAuthorizedCallerHub(vm.addr(2), true);
//         assertTrue(aclManager.authorizedCallersHub(vm.addr(2)));

//         // Set authorized caller works for false
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerHubUpdated(vm.addr(2), false);
//         aclManager.setAuthorizedCallerHub(vm.addr(2), false);
//         assertFalse(aclManager.authorizedCallersHub(vm.addr(2)));
//     }

//     function test_setAuthorizedCallerStakePool() public {
//         // Only owner can set authorized caller
//         vm.expectRevert();
//         aclManager.setAuthorizedCallerStakePool(vm.addr(2), true);

//         // New caller cannot be the zero address
//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: caller is the zero address");
//         aclManager.setAuthorizedCallerStakePool(address(0), true);

//         // Set authorized caller works for true
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerStakePoolUpdated(vm.addr(2), true);
//         aclManager.setAuthorizedCallerStakePool(vm.addr(2), true);
//         assertTrue(aclManager.authorizedCallersStakePool(vm.addr(2)));

//         // Set authorized caller works for false
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerStakePoolUpdated(vm.addr(2), false);
//         aclManager.setAuthorizedCallerStakePool(vm.addr(2), false);
//         assertFalse(aclManager.authorizedCallersStakePool(vm.addr(2)));
//     }

//     function test_setAuthorizedCallerToken() public {
//         // Only owner can set authorized caller
//         vm.expectRevert();
//         aclManager.setAuthorizedCallerToken(vm.addr(2), true);

//         // New caller cannot be the zero address
//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: caller is the zero address");
//         aclManager.setAuthorizedCallerToken(address(0), true);

//         // Set authorized caller works for true
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerTokenUpdated(vm.addr(2), true);
//         aclManager.setAuthorizedCallerToken(vm.addr(2), true);
//         assertTrue(aclManager.authorizedCallersToken(vm.addr(2)));

//         // Set authorized caller works for false
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerTokenUpdated(vm.addr(2), false);
//         aclManager.setAuthorizedCallerToken(vm.addr(2), false);
//         assertFalse(aclManager.authorizedCallersToken(vm.addr(2)));
//     }

//     function test_setAuthorizedCallerLoanManager() public {
//         // Only owner can set authorized caller
//         vm.expectRevert();
//         aclManager.setAuthorizedCallerLoanManager(vm.addr(2), true);

//         // New caller cannot be the zero address
//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: caller is the zero address");
//         aclManager.setAuthorizedCallerLoanManager(address(0), true);

//         // Set authorized caller works for true
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerLoanManagerUpdated(vm.addr(2), true);
//         aclManager.setAuthorizedCallerLoanManager(vm.addr(2), true);
//         assertTrue(aclManager.authorizedCallersLoanManager(vm.addr(2)));

//         // Set authorized caller works for false
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerLoanManagerUpdated(vm.addr(2), false);
//         aclManager.setAuthorizedCallerLoanManager(vm.addr(2), false);
//         assertFalse(aclManager.authorizedCallersLoanManager(vm.addr(2)));
//     }

//     function test_setAuthorizedCallerBlacklister() public {
//         // Only owner can set authorized caller
//         vm.expectRevert();
//         aclManager.setAuthorizedCallerBlacklister(vm.addr(2), true);

//         // New caller cannot be the zero address
//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: caller is the zero address");
//         aclManager.setAuthorizedCallerBlacklister(address(0), true);

//         // Set authorized caller works for true
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerBlacklisterUpdated(vm.addr(2), true);
//         aclManager.setAuthorizedCallerBlacklister(vm.addr(2), true);
//         assertTrue(aclManager.authorizedCallersBlacklister(vm.addr(2)));

//         // Set authorized caller works for false
//         vm.prank(owner);
//         vm.expectEmit(true, true, false, false);
//         emit AuthorizedCallerBlacklisterUpdated(vm.addr(2), false);
//         aclManager.setAuthorizedCallerBlacklister(vm.addr(2), false);
//         assertFalse(aclManager.authorizedCallersBlacklister(vm.addr(2)));
//     }

//     function test_pause() public {
//         // Only the owner can call pause
//         vm.expectRevert();
//         aclManager.pause();

//         // Owner can call only if unpaused
//         bytes32 value = bytes32(uint256(1)) << 20 * 8;
//         vm.store(address(aclManager), bytes32(uint256(1)), value);

//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: paused");
//         aclManager.pause();

//         value = bytes32(uint256(0)) << 20 * 8;
//         vm.store(address(aclManager), bytes32(uint256(1)), value);

//         // Pause works
//         vm.prank(owner);
//         vm.expectEmit(false, false, false, true);
//         emit Paused(owner);
//         aclManager.pause();
//     }

//     function test_unpause() public {
//         // Only the owner can call unpause
//         vm.expectRevert();
//         aclManager.unpause();

//         // Owner can call only if unpaused
//         bytes32 value = bytes32(uint256(0)) << 20 * 8;
//         vm.store(address(aclManager), bytes32(uint256(1)), value);

//         vm.prank(owner);
//         vm.expectRevert("ACL Manager: not paused");
//         aclManager.unpause();

//         value = bytes32(uint256(1)) << 20 * 8;
//         vm.store(address(aclManager), bytes32(uint256(1)), value);

//         // Unpause works
//         vm.prank(owner);
//         vm.expectEmit(false, false, false, true);
//         emit Unpaused(owner);
//         aclManager.unpause();
//     }
}
