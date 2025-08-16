// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeploySubVault.s.sol";
import "../../src/SubscriptionVault.sol";
import "../../src/mocks/MockUSDC.sol";

contract DeploySubVaultTest is Test {
    DeploySubVault deployScript;

    function setUp() public {
        deployScript = new DeploySubVault();
    }

    function testDeployScriptRunsAndDeploys() public {
        (SubscriptionVault vault, MockUSDC usdc) = deployScript.run();

        // assertions
        assertTrue(address(vault) != address(0), "vault should be deployed");
        assertTrue(address(usdc) != address(0), "USDC mock should be deployed");

        // check vault wiring
        assertEq(address(vault.paymentToken()), address(usdc), "vault USDC token mismatch");

        // vault should start with no subscriptions
        SubscriptionVault.Subscription[] memory subs = vault.getSubscriptionsForUser(address(this));
        assertEq(subs.length, 0, "should be no subscriptions yet");

        vm.stopPrank();
    }
}
