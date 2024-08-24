// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/FlappyQFFactory.sol";
import "../src/MockUSDC.sol";

contract FlappyQFFactoryTest is Test {
    FlappyQFFactory public factory;
    MockUSDC public mockUSDC;
    address public owner;
    address public user;
    address constant AIRNODE_RRP = 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d;

    function setUp() public {
        owner = address(this);
        user = address(0x2);
        mockUSDC = new MockUSDC("Mock USDC", "mUSDC");
        factory = new FlappyQFFactory(address(mockUSDC), AIRNODE_RRP);
    }

    function testInitialState() public {
        assertEq(address(factory.usdcToken()), address(mockUSDC));
        assertEq(factory.owner(), owner);
    }

    function testSetRequestParameters() public {
        address airnode = address(0x2);
        bytes32 endpointIdUint256 = bytes32(uint256(1));
        address sponsorWallet = address(0x3);

        factory.setRequestParameters(airnode, endpointIdUint256, sponsorWallet);

        assertEq(factory.airnode(), airnode);
        assertEq(factory.endpointIdUint256(), endpointIdUint256);
        assertEq(factory.sponsorWallet(), sponsorWallet);
    }

    function testSetProxyAddresses() public {
        uint256 chainId = 1;
        address ethUsdProxy = address(0x4);
        address usdcUsdProxy = address(0x5);

        factory.setProxyAddresses(chainId, ethUsdProxy, usdcUsdProxy);

        assertEq(factory.ethUsdProxies(chainId), ethUsdProxy);
        assertEq(factory.usdcUsdProxies(chainId), usdcUsdProxy);
    }

    function testFundMatchingPool() public {
        uint256 initialFactoryBalance = mockUSDC.balanceOf(address(factory));
        console2.log("Initial factory balance: ", initialFactoryBalance);
        uint256 amount = 10_000 * 10 ** 6; // 100,000 USDC

        //mint some to the owner
        mockUSDC.mint(owner, amount);
        mockUSDC.approve(address(factory), amount);

        uint256 initialOwnerBalance = mockUSDC.balanceOf(owner);
        console2.log("Initial owner balance: ", initialOwnerBalance);

        //switch the user to the owner
        factory.fundMatchingPool(10000000000);

        assertEq(
            mockUSDC.balanceOf(address(factory)),
            initialFactoryBalance + amount
        );
        assertEq(mockUSDC.balanceOf(owner), initialOwnerBalance - amount);
    }

    function testWithdrawMatchingPool() public {
        uint256 amount = 100_000 * 10 ** 6; // 100,000 USDC

        factory.withdrawMatchingPool(amount);

        assertEq(mockUSDC.balanceOf(address(factory)), 900_000 * 10 ** 6);
        assertEq(mockUSDC.balanceOf(owner), amount);
    }

    // Add more tests for createProject, makeRequestUint256, and fulfillUint256 functions
    // These tests might require mocking external contracts like IProxy and FlappyQF
}
