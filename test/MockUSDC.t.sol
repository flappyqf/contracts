// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/MockUSDC.sol";

contract MockUSDCTest is Test {
    MockUSDC public mockUSDC;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        mockUSDC = new MockUSDC("Mock USDC", "mUSDC");
    }

    function testInitialState() public {
        assertEq(mockUSDC.name(), "Mock USDC");
        assertEq(mockUSDC.symbol(), "mUSDC");
        assertEq(mockUSDC.decimals(), 6);
        assertEq(mockUSDC.totalSupply(), 0);
    }

    function testMint() public {
        uint256 amount = 1000 * 10 ** 6; // 1000 USDC
        mockUSDC.mint(user, amount);
        assertEq(mockUSDC.balanceOf(user), amount);
        assertEq(mockUSDC.totalSupply(), amount);
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10 ** 6; // 1000 USDC
        mockUSDC.mint(owner, amount);
        mockUSDC.transfer(user, 500 * 10 ** 6);
        assertEq(mockUSDC.balanceOf(owner), 500 * 10 ** 6);
        assertEq(mockUSDC.balanceOf(user), 500 * 10 ** 6);
    }

    function testTransferFrom() public {
        uint256 amount = 1000 * 10 ** 6; // 1000 USDC
        mockUSDC.mint(owner, amount);
        mockUSDC.approve(user, 500 * 10 ** 6);
        vm.prank(user);
        mockUSDC.transferFrom(owner, user, 500 * 10 ** 6);
        assertEq(mockUSDC.balanceOf(owner), 500 * 10 ** 6);
        assertEq(mockUSDC.balanceOf(user), 500 * 10 ** 6);
    }
}
