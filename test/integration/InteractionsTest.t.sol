// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/SubscriptionVault.sol";
import "../../src/mocks/MockUSDC.sol";

contract InteractionsTest is Test {
    SubscriptionVault vault;
    MockUSDC usdc;

    address user1 = address(0x123);
    address user2 = address(0x456);

    address merchant1 = address(0xAAA);
    address merchant2 = address(0xBBB);

    function setUp() public {
        usdc = new MockUSDC(1_000_000 ether);

        vault = new SubscriptionVault(usdc);

        usdc.mint(user1, 1000 ether);
        usdc.mint(user2, 500 ether);

        vm.prank(user1);
        usdc.approve(address(vault), 1000 ether);

        vm.prank(user2);
        usdc.approve(address(vault), 500 ether);
    }

    function testUserSubscriptionsFlow() public {
        vm.prank(user1);
        bytes32 sub1 = vault.createSubscription(merchant1, address(usdc), 100 ether, 30 days);

        vm.prank(user2);
        bytes32 sub2 = vault.createSubscription(merchant2, address(usdc), 50 ether, 15 days);

        (,,, uint256 amount1,,,, bool active1) = vault.getSubscription(sub1);
        (,,, uint256 amount2,,,, bool active2) = vault.getSubscription(sub2);

        assertEq(amount1, 100 ether);
        assertEq(amount2, 50 ether);
        assertTrue(active1);
        assertTrue(active2);

        vm.warp(block.timestamp + 30 days);
        vault.processPayment(sub1);
        vault.processPayment(sub2);

        vm.prank(user1);
        vault.cancelSubscription(sub1);

        (,,,,,,, bool activeAfterCancel) = vault.getSubscription(sub1);
        assertFalse(activeAfterCancel);

        (,,,,,,, bool active2After) = vault.getSubscription(sub2);
        assertTrue(active2After);
    }
}
