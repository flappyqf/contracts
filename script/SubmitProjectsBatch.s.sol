// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {FlappyQF} from "../src/FlappyQF.sol";

contract SubmitProjectsBatch is Script {
    function run() external {
        uint256 privKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(privKey);

        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        address contractAddress = 0xDA65F7b3F73A1CF6cd4f36f234c9336aC1eEf270;
        FlappyQF flappyQF = FlappyQF(contractAddress);

        vm.startBroadcast(deployer);

        // Submit projects
        for (uint256 i = 0; i < 8; i++) {
            string memory ipfsHash = string(
                abi.encodePacked("QmHash", vm.toString(i))
            );
            flappyQF.submitProject("test", payable(deployer));
            console2.log("Submitted project ", i);
        }

        // Accept projects
        for (uint256 i = 0; i < 8; i++) {
            flappyQF.acceptProject(i);
            console2.log("Accepted project ", i);
        }

        // Initiate matching
        flappyQF.initiateMatching();
        console2.log("Initiated matching");

        vm.stopBroadcast();
    }
}
