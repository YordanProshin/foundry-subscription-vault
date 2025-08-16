// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/libraries/SubscriptionLib.sol";
import "../../src/mocks/MockUSDC.sol";

/// @notice Tiny harness that holds one Subscription in storage and exposes helpers.
contract SubscriptionLibHarness {
    using SubscriptionLib for SubscriptionLib.Subscription;

    SubscriptionLib.Subscription internal sub;

    // Expose the library's external create()
    function createSub(
        address user,
        address provider,
        address token,
        uint256 amount,
        uint256 interval,
        uint256 paymentId
    ) external {
        sub.create(user, provider, token, amount, interval, paymentId);
    }

    // Expose the library's external isDue()
    function isDue() external view returns (bool) {
        return sub.isDue();
    }

    // Accessors/mutators to drive branches in isDue()
    function get() external view returns (SubscriptionLib.Subscription memory s) {
        s = sub;
    }

    function setActive(bool v) external {
        sub.isActive = v;
    }

    function setPaused(bool v) external {
        sub.isPaused = v;
    }

    function setLastPaid(uint256 ts) external {
        sub.lastPaid = ts;
    }

    function setInterval(uint256 ivl) external {
        sub.interval = ivl;
    }

    // Expose the internal Days() from the library
    function daysHelper(uint256 n) external pure returns (uint256) {
        return SubscriptionLib.Days(n);
    }

    // Re-declare event to expect it in tests (emits in harness context via DELEGATECALL)
    event SubscriptionCreated(
        uint256 indexed paymentId,
        address indexed user,
        address indexed provider,
        address token,
        uint256 amount,
        uint256 interval
    );
}

contract SubscriptionLibTest is Test {
    using stdStorage for StdStorage;

    SubscriptionLibHarness harness;
    MockUSDC usdc;

    address user = address(0xBEEF);
    address provider = address(0xCAFE);

    function setUp() public {
        harness = new SubscriptionLibHarness();
        usdc = new MockUSDC(1_000_000e6);
    }

    function testCreate_PopulatesAndEmits() public {
        uint256 amount = 123e6;
        uint256 interval = 1 days;
        uint256 pid = 42;

        vm.expectEmit(address(harness));
        emit SubscriptionLibHarness.SubscriptionCreated(pid, user, provider, address(usdc), amount, interval);

        uint256 start = block.timestamp;
        harness.createSub(user, provider, address(usdc), amount, interval, pid);

        SubscriptionLib.Subscription memory s = harness.get();
        assertEq(s.user, user);
        assertEq(s.provider, provider);
        assertEq(s.token, address(usdc));
        assertEq(s.amount, amount);
        assertEq(s.interval, interval);
        assertEq(s.paymentId, pid);
        assertEq(s.lastPaid, start);
        assertTrue(s.isActive);
        assertFalse(s.isPaused);
    }

    function testCreate_Revert_UserZero() public {
        vm.expectRevert(bytes("User zero address"));
        harness.createSub(address(0), provider, address(usdc), 1, 1 days, 1);
    }

    function testCreate_Revert_ProviderZero() public {
        vm.expectRevert(bytes("Provider zero address"));
        harness.createSub(user, address(0), address(usdc), 1, 1 days, 1);
    }

    function testCreate_Revert_TokenZero() public {
        vm.expectRevert(bytes("Token zero address"));
        harness.createSub(user, provider, address(0), 1, 1 days, 1);
    }

    function testCreate_Revert_AmountZero() public {
        vm.expectRevert(bytes("Zero amount"));
        harness.createSub(user, provider, address(usdc), 0, 1 days, 1);
    }

    function testCreate_Revert_IntervalTooShort() public {
        vm.expectRevert(bytes("Interval too short"));
        harness.createSub(user, provider, address(usdc), 1, 3599, /* < 1h */ 1);
    }

    function testIsDue_FalseImmediatelyAfterCreate() public {
        harness.createSub(user, provider, address(usdc), 1, 1 days, 1);
        assertFalse(harness.isDue(), "should NOT be due right away");
    }

    function testIsDue_TrueAtOrAfterInterval() public {
        harness.createSub(user, provider, address(usdc), 1, 1 days, 1);

        vm.warp(block.timestamp + 1 days - 1);
        assertFalse(harness.isDue(), "1 second early should still be false");

        vm.warp(block.timestamp + 1);
        assertTrue(harness.isDue(), "exactly at interval should be true");
    }

    function testIsDue_FalseWhenInactiveOrPaused() public {
        harness.createSub(user, provider, address(usdc), 1, 1 days, 1);
        vm.warp(block.timestamp + 1 days);

        harness.setActive(false);
        assertFalse(harness.isDue(), "inactive never due");
        harness.setActive(true);

        harness.setPaused(true);
        assertFalse(harness.isDue(), "paused never due");
        harness.setPaused(false);

        assertTrue(harness.isDue(), "active & unpaused at/after interval");
    }
}
