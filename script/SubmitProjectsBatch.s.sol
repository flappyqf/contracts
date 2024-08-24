// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {FlappyQF} from "../src/FlappyQF.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract SubmitProjectsBatch is Script {
    function run() external {
        uint256 privKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(privKey);

        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        address flappyQfFactoryAddress = 0xe9E4af72b567a9CBD6460CDA0466D071934e890d;
        address flappyQfContractAddress = 0xb72cB3Cac841CeafCE22422179442Bd200C24417;
        address usdcTokenAddress = 0x460c44641673b2fB1d7D769f01B309EAA5eAc533;
        FlappyQF flappyQF = FlappyQF(flappyQfContractAddress);

        vm.startBroadcast(deployer);

        //create an array of IPFS hashes
        uint256 numberOfProjects = 8;
        string[] memory ipfsHashes = new string[](numberOfProjects);
        ipfsHashes[0] = "QmTZ3X1XcdR74g3PMYJXnaqnDky9PSeBzqBXv78snK5Ajx";
        ipfsHashes[1] = "QmcHf1cKvrZosDVK8iZ8j2nF6urS5CCGbfdMX9RmHtb9q6";
        ipfsHashes[2] = "QmQvjbVTCCZaQimbiPRMVWZFgYEuYG6Niuoovv9v9sCv8P";
        ipfsHashes[3] = "QmWy8rKQg1nMteVXQbSyijiAzw6KeoXmchyn6exrNdnqR3";
        ipfsHashes[4] = "QmR3rTQokuxgGJyhfPCRNcG1eZ69wzEDnJqrJcbPbuDgVM";
        ipfsHashes[5] = "Qmf1VxzU8PFH3k3ia7GYFzcnY9hJe5VAwefSieSpLZi1GH";
        ipfsHashes[6] = "QmRAC4ZuGHAgaCCPpYX1E3wAjkRaSwoiox2jv1pWs3avtB";
        ipfsHashes[7] = "QmbtVgkRcs7v1BMVqq6kiCTDfYKTJYDM762Yf1z862GvWb";

        // Submit projects
        for (uint256 i = 0; i < 8; i++) {
            string memory ipfsHash = ipfsHashes[i];
            flappyQF.submitProject(ipfsHash, payable(deployer));
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
