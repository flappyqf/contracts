// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FlappyQF} from "../src/FlappyQF.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract DonateToProjects is Script {
    function run() external {
        uint256 deployerPrivKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(deployerPrivKey);

        address usdcAddress = 0xCF6bc8d4d55B4BABA1E7783400F3Bf7FbD55CF5b; // MockUSDC address
        address flappyQFAddress = 0xb72cB3Cac841CeafCE22422179442Bd200C24417; // FlappyQF address

        IERC20 usdc = IERC20(usdcAddress);
        FlappyQF flappyQF = FlappyQF(flappyQFAddress);

        vm.startBroadcast(deployer);

        // Generate and fund 8 wallets, then donate, randomize the number of USDC donated and also the number of contributors that each project got
        for (uint256 i = 0; i < 8; i++) {
            uint256 privateKey = uint256(
                keccak256(abi.encodePacked("wallet", i))
            );
            address wallet = vm.addr(privateKey);

            console2.log("Wallet", i);
            console2.log("Private Key:", uint256ToHexString(privateKey));
            console2.log("Address:", wallet);

            // Transfer ETH for gas from the deployer to the wallet
            payable(wallet).transfer(0.0001 ether);

            // Transfer high amount of USDC to the wallet
            uint256 usdcAmount = 1_000_000_000_000_000_000; // 1 USDC
            MockUSDC(usdcAddress).mint(wallet, usdcAmount);

            console2.log(
                "Funded wallet with 0.00001 ETH and",
                usdcAmount / 10 ** 6,
                "USDC"
            );

            // Stop the current broadcast
            vm.stopBroadcast();

            // Start a new broadcast as the wallet
            vm.startBroadcast(privateKey);

            // Donate random amount to random number of projects
            uint256 projectsToDonate = (1 +
                (uint256(keccak256(abi.encodePacked(block.timestamp, i))) % 4)); // Donate to 1-3 projects
            for (uint256 j = 0; j < projectsToDonate; j++) {
                uint256 projectId = (uint256(
                    keccak256(abi.encodePacked(block.timestamp, i))
                ) % 8); // Choose a random project (0-7)
                uint256 donationAmount = (10 +
                    (uint256(keccak256(abi.encodePacked(block.timestamp, i))) %
                        (usdcAmount / 10 ** 6 - 10))) * 10 ** 6; // Donate between 10 and all available USDC

                usdc.approve(address(flappyQF), donationAmount);
                flappyQF.contributeToProject(projectId, donationAmount);

                console2.log(
                    "Donated",
                    donationAmount / 10 ** 6,
                    "USDC to project",
                    projectId
                );

                usdcAmount -= donationAmount;
                if (usdcAmount < 10 * 10 ** 6) break; // Stop if less than 10 USDC left
            }

            console2.log("---");

            // Stop the wallet's broadcast
            vm.stopBroadcast();

            // Resume broadcasting as the deployer
            vm.startBroadcast(deployer);
        }

        vm.stopBroadcast();
    }

    function uint256ToHexString(
        uint256 value
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 64; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + uint256(value % 16)));
            if (uint8(buffer[i - 1]) > 57) {
                buffer[i - 1] = bytes1(uint8(buffer[i - 1]) + 39);
            }
            value /= 16;
        }
        return string(buffer);
    }
}
