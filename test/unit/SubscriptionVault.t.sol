// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionVault} from "src/SubscriptionVault.sol";
import {MockUSDC} from "src/mocks/MockUSDC.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SubscriptionVaultTest is Test {
    using SafeERC20 for IERC20;

    SubscriptionVault public vault;
    MockUSDC public usdc;

    address public subscriber = address(0x1);
    address public merchant = address(0x2);
    address public notSubscriber = address(0x3);
    address public owner;

    bytes32 public subId;

    function setUp() public {
        usdc = new MockUSDC(10_000);
        owner = address(this);

        vault = new SubscriptionVault(IERC20(address(usdc)));

        usdc.mint(subscriber, 1000 * 1e6); // 1,000 USDC

        vm.startPrank(subscriber);
        usdc.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.label(subscriber, "Subscriber");
        vm.label(merchant, "Merchant");
        vm.label(owner, "Owner");
    }

    function test_CreateSubscription_Success() public {
        vm.prank(subscriber);
        bytes32 subscriberId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        assertTrue(subscriberId != bytes32(0), "ID should be generated");
    }

    function test_CreateSubscription_UniqueId_PreventsDuplicates() public {
        vm.prank(subscriber);
        bytes32 id1 = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        vm.warp(100);

        vm.prank(subscriber);
        bytes32 id2 = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        assertTrue(id1 != id2, "IDs should differ over time");
    }

    function test_ProcessPayment_Success() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            7 days
        );

        vm.warp(block.timestamp + 8 days); // Fast-forward past due date

        vm.expectEmit(true, true, false, false);
        emit SubscriptionVault.PaymentProcessed(subId, block.timestamp, true);

        vault.processPayment(subId);

        SubscriptionVault.Subscription memory sub = vault.subscriptions(subId);
        assertTrue(sub.nextDue > block.timestamp, "Next due not updated");
        assertEq(
            usdc.balanceOf(merchant),
            100 * 1e6,
            "Merchant didn't receive funds"
        );
    }

    function test_ProcessPayment_TooEarly_Reverts() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        vm.expectRevert();
        vault.processPayment(subId);
    }

    function test_ProcessPayment_Inactive_Reverts() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            7 days
        );

        vm.prank(subscriber);
        vault.cancelSubscription(subId);

        vm.warp(block.timestamp + 8 days);

        vm.expectRevert(bytes("Inactive subscription"));
        vault.processPayment(subId);
    }

    function test_CancelSubscription_BySubscriber_Success() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        vm.prank(subscriber);
        vm.expectEmit(true, true, false, false);
        emit SubscriptionVault.SubscriptionCancelled(subId);
        vault.cancelSubscription(subId);

        SubscriptionVault.Subscription memory sub = vault.subscriptions(subId);
        assertFalse(sub.active, "Should be inactive");
    }

    function test_CancelSubscription_Unauthorized_Reverts() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            30 days
        );

        vm.prank(notSubscriber);
        vm.expectRevert(bytes("Not subscriber"));
        vault.cancelSubscription(subId);
    }

    function test_ProcessMultiplePayments() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            5 days
        );

        for (uint256 i = 0; i < 3; i++) {
            vm.warp(block.timestamp + 6 days); // Advance to due date
            vault.processPayment(subId);

            SubscriptionVault.Subscription memory sub = vault.subscriptions(
                subId
            );
            assertEq(sub.lastPaid, block.timestamp, "Last paid not updated");
        }

        assertEq(
            usdc.balanceOf(merchant),
            300 * 1e6,
            "Merchant balance mismatch"
        );
    }

    function test_ProcessPayment_AfterCancel_Reverts() public {
        vm.prank(subscriber);
        subId = vault.createSubscription(
            merchant,
            address(usdc),
            100 * 1e6,
            7 days
        );

        vm.prank(subscriber);
        vault.cancelSubscription(subId);

        vm.warp(block.timestamp + 8 days);

        vm.expectRevert(bytes("Inactive subscription"));
        vault.processPayment(subId);
    }
}

contract RevertingToken is IERC20 {
    function totalSupply() external pure override returns (uint256) {
        return 0;
    }

    function balanceOf(address) external pure override returns (uint256) {
        return 1000 * 1e6;
    }

    function transfer(address, uint256) external pure override returns (bool) {
        revert();
    }

    function allowance(
        address,
        address
    ) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert("TransferFrom failed");
    }
}
