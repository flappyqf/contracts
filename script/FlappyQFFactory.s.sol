// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {FlappyQFFactory} from "../src/FlappyQFFactory.sol";
import {FlappyQF} from "../src/FlappyQF.sol";
import {GameVerifier} from "../src/GameVerifier.sol";
import {GameProof} from "../src/GameVerifierContract.sol";

contract DeployFlappyQFFactory is Script {
    function run() external {
        uint256 privKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(privKey);

        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        vm.startBroadcast(deployer);

        address usdcToken = 0xc33c0203a9F4eA06e2627Fc6635518D6C2993ddF;
        address airnodeRrp = 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d;

        // Deploy FlappyQFFactory
        FlappyQFFactory factory = new FlappyQFFactory(
            address(usdcToken),
            address(airnodeRrp),
            address(0)
        );

        FlappyQF flappyQF = new FlappyQF(
            8,
            address(factory),
            usdcToken,
            address(0)
        );

        vm.stopBroadcast();
    }
}
