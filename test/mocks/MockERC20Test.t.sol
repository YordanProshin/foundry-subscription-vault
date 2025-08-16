// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockERC20("MockToken", "MTK");
    }

    function testMintIncreasesBalance() public {
        uint256 amount = 1_000 ether;
        token.mint(alice, amount);

        assertEq(token.balanceOf(alice), amount, "minted balance mismatch");
        assertEq(token.totalSupply(), amount, "supply mismatch");
    }

    function testTransferWorks() public {
        uint256 amount = 500 ether;

        token.mint(alice, amount);
        vm.prank(alice);
        token.transfer(bob, 200 ether);

        assertEq(token.balanceOf(alice), 300 ether, "alice balance wrong");
        assertEq(token.balanceOf(bob), 200 ether, "bob balance wrong");
    }

    function testApproveAndTransferFrom() public {
        uint256 amount = 1000 ether;
        token.mint(alice, amount);

        vm.prank(alice);
        token.approve(bob, 400 ether);

        vm.prank(bob);
        token.transferFrom(alice, bob, 400 ether);

        assertEq(token.balanceOf(alice), 600 ether, "alice balance wrong");
        assertEq(token.balanceOf(bob), 400 ether, "bob balance wrong");
    }

    function testMintZeroAmount() public {
        token.mint(alice, 0);
        assertEq(
            token.balanceOf(alice),
            0,
            "zero mint should not increase balance"
        );
        assertEq(
            token.totalSupply(),
            0,
            "zero mint should not increase supply"
        );
    }
}
