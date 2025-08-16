// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// ✅ Inherit from OpenZeppelin's ERC20, which implements IERC20
contract MockUSDC is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    // Optional: Mint more for testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // USDC standard: 6 decimals
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
