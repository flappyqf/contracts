// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract DeployMockUSDC is Script {
    function run() external {
        uint256 privKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(privKey);

        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        vm.startBroadcast(deployer);

        // Deploy MockUSDC
        MockUSDC mockUSDC = new MockUSDC("Mock USDC", "mUSDC");
        console2.log("MockUSDC deployed at: ", address(mockUSDC));

        // Mint 1,000,000,000,000,000 tokens to the deployer
        uint256 mintAmount = 1_000_000_000 * 10 ** 6; // 1 billion tokens with 6 decimal places
        mockUSDC.mint(deployer, mintAmount);
        console2.log("Minted ", mintAmount, " tokens to deployer");

        vm.stopBroadcast();

        // Log final state
        console2.log("Deployer balance: ", mockUSDC.balanceOf(deployer));
        console2.log("Total supply: ", mockUSDC.totalSupply());
    }
}
