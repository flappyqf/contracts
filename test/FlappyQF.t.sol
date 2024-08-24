// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/FlappyQF.sol";
import "../src/FlappyQFFactory.sol";
import "../src/MockUSDC.sol";

contract FlappyQFTest is Test {
    FlappyQF public flappyQF;
    FlappyQFFactory public factory;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        MockUSDC mockUSDC = new MockUSDC("Mock USDC", "mUSDC");
        address AIRNODE_RRP = 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d;
        factory = new FlappyQFFactory(address(mockUSDC), AIRNODE_RRP);

        // Transfer mockUSDC to factory
        mockUSDC.mint(owner, 1000000000000);
        mockUSDC.approve(address(factory), 1000000000000);

        factory.fundMatchingPool(1000000000000);

        // Create rounds using the factory
        vm.prank(owner);
        factory.createRound(8, 1 ether);

        // Set flappyQF to the first created round
        flappyQF = FlappyQF(factory.rounds(0));

        vm.deal(user, 100 ether);
    }

    function testSubmitProject() public {
        vm.prank(user);
        flappyQF.submitProject("QmTest123");
        (string memory ipfsHash, bool accepted) = flappyQF.projects(0);
        assertEq(ipfsHash, "QmTest123");
        assertFalse(accepted);
    }

    function testAcceptProject() public {
        vm.prank(user);
        flappyQF.submitProject("QmTest123");

        vm.prank(owner);
        flappyQF.acceptProject(0);

        (, bool accepted) = flappyQF.projects(0);
        assertTrue(accepted);
    }

    function testInitiateAndCompleteMatching() public {
        // Submit and accept 8 projects
        for (uint i = 0; i < 8; i++) {
            flappyQF.submitProject(string(abi.encodePacked("QmTest", i)));
            flappyQF.acceptProject(i);
        }

        flappyQF.initiateMatching();

        flappyQF.completeMatching();

        assertEq(flappyQF.currentRound(), 1);
        assertEq(flappyQF.matchesPerRound(), 4);
    }

    function testSetMatchWinner() public {
        testInitiateAndCompleteMatching();

        vm.prank(owner);
        flappyQF.setMatchWinner(0, 0);
        assertEq(flappyQF.matchWinners(1, 0), 0);
    }

    function testAdvanceRounds() public {
        testInitiateAndCompleteMatching();

        // Set winners for all matches in the first round
        for (uint i = 0; i < 4; i++) {
            vm.prank(owner);
            flappyQF.setMatchWinner(i, i);
        }

        assertEq(flappyQF.currentRound(), 2);
        assertEq(flappyQF.matchesPerRound(), 2);
        assertEq(
            uint(flappyQF.currentStage()),
            uint(FlappyQF.RoundStage.SemiFinals)
        );
    }

    //function to show the bracket
    function testShowBracket() public {
        testInitiateAndCompleteMatching();
        uint256[] memory bracket = flappyQF.getBracketByRound(0);
        assertEq(bracket[0], 0);
        assertEq(bracket[1], 1);
        assertEq(bracket[2], 2);
        assertEq(bracket[3], 3);
        assertEq(bracket[4], 4);
        assertEq(bracket[5], 5);
        assertEq(bracket[6], 6);
        assertEq(bracket[7], 7);
    }
}
