// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FlappyQF} from "../src/FlappyQF.sol";

contract DonateToProjects is Script {
    function run() external {
        uint256 deployerPrivKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(deployerPrivKey);

        address usdcAddress = 0x84C893d0a3D9AAa2f5c89db90309d7dDe1FC4fCe; // MockUSDC address
        address flappyQFAddress = 0xDA65F7b3F73A1CF6cd4f36f234c9336aC1eEf270; // FlappyQF address

        IERC20 usdc = IERC20(usdcAddress);
        FlappyQF flappyQF = FlappyQF(flappyQFAddress);

        vm.startBroadcast(deployer);

        // Generate and fund 8 wallets, then donate
        for (uint256 i = 0; i < 8; i++) {
            uint256 privateKey = uint256(
                keccak256(abi.encodePacked("wallet", i))
            );
            address wallet = vm.addr(privateKey);

            console2.log("Wallet", i);
            console2.log("Private Key:", uint256ToHexString(privateKey));
            console2.log("Address:", wallet);

            // Transfer ETH for gas
            payable(wallet).transfer(0.1 ether);

            // Transfer 1000 USDC
            usdc.transfer(wallet, 1000 * 10 ** 6);

            console2.log("Funded wallet with 0.1 ETH and 1000 USDC");

            // Stop the current broadcast
            vm.stopBroadcast();

            // Start a new broadcast as the wallet
            vm.startBroadcast(privateKey);

            // Donate to project
            usdc.approve(address(flappyQF), 100 * 10 ** 6);
            flappyQF.contributeToProject(i, 100 * 10 ** 6);

            console2.log("Donated 100 USDC to project", i);
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
