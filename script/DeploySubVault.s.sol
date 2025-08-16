// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SubscriptionVault} from "src/SubscriptionVault.sol";
import {MockUSDC} from "src/mocks/MockUSDC.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeploySubVault is Script {
    function run() external returns (SubscriptionVault, MockUSDC) {
        vm.startBroadcast();

        MockUSDC usdc = new MockUSDC(1_000_000); // 1M tokens

        SubscriptionVault vault = new SubscriptionVault(IERC20(usdc));

        console.log("Deployed MockUSDC at:", address(usdc));
        console.log("Deployed SubscriptionVault at:", address(vault));

        vm.stopBroadcast();

        return (vault, usdc);
    }
}
