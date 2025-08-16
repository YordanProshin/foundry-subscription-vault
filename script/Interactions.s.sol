// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/SubscriptionVault.sol";
import "../src/mocks/MockUSDC.sol";

contract Interactions is Script {
    function run() external {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC(1_000_000 ether);

        SubscriptionVault vault = new SubscriptionVault(usdc);

        address user1 = address(0x123);
        address user2 = address(0x456);

        usdc.mint(user1, 1000 ether);
        usdc.mint(user2, 500 ether);

        vm.prank(user1);
        usdc.approve(address(vault), 1000 ether);

        vm.prank(user2);
        usdc.approve(address(vault), 500 ether);

        vm.prank(user1);
        vault.createSubscription(address(user1), address(usdc), 100 ether, 30 days);

        vm.prank(user2);
        vault.createSubscription(address(user2), address(usdc), 50 ether, 15 days);

        vm.warp(block.timestamp + 30 days);
        vault.processPayment("sub1");

        vm.warp(block.timestamp + 15 days);
        vault.processPayment("sub2");

        vm.prank(user1);
        vault.cancelSubscription("sub1");

        vm.stopBroadcast();
    }
}
