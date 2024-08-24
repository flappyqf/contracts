// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {FlappyQF} from "../src/FlappyQF.sol";
import {FlappyQFFactory} from "../src/FlappyQFFactory.sol";
import {GameVerifier} from "../src/GameVerifier.sol";
import {GameProof} from "../src/GameVerifierContract.sol";

contract UpdateGameVerifier is Script {
    function run() external {
        uint256 privKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(privKey);

        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        // Addresses of existing contracts
        address factoryAddress = 0x460c44641673b2fB1d7D769f01B309EAA5eAc533;

        vm.startBroadcast(deployer);

        //Deploy GameVerifier
        GameVerifier gameVerifier = new GameVerifier();
        console2.log("GameVerifier deployed at: ", address(gameVerifier));

        // Deploy GameProof
        GameProof gameProof = new GameProof(address(gameVerifier));
        console2.log("GameProof deployed at: ", address(gameProof));

        // Update GameProof address in Factory
        FlappyQFFactory factory = FlappyQFFactory(payable(factoryAddress));

        factory.setGameVerifier(address(gameProof));
        console2.log("GameVerifier address updated in Factory");

        vm.stopBroadcast();

        console2.log("Update completed successfully");
    }
}
