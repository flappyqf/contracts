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

        address usdcToken = 0x84C893d0a3D9AAa2f5c89db90309d7dDe1FC4fCe;
        address airnodeRrp = 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d;

        // Deploy FlappyQFFactory
        FlappyQFFactory factory = new FlappyQFFactory(
            address(0),
            address(0),
            address(0)
        );

        FlappyQF flappyQF = new FlappyQF(
            8,
            address(factory),
            usdcToken,
            address(0)
        );
    }
}
