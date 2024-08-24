// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {FlappyQF} from "../src/FlappyQF.sol";

contract SubmitGameProof is Script {
    function run() external {
        uint256 deployerPrivKey = vm.envUint("PRIV_KEY");
        address deployer = vm.rememberKey(deployerPrivKey);

        vm.startBroadcast(deployer);
        address flappyQFAddress = 0xDA65F7b3F73A1CF6cd4f36f234c9336aC1eEf270; // FlappyQF address
        FlappyQF flappyQF = FlappyQF(flappyQFAddress);
        uint256 projectId = 0; // Assuming project ID is 0

        uint[2] memory a = [
            0x2978d1513257b59605566836466a6dcbe084b840151dde98fc2f4f5af2d8f062,
            0x0fe80d2935e0d3982222fbc14a75b4e40ec2b16810292a6e698a4edbbff2f8cb
        ];

        uint[2][2] memory b = [
            [
                0x2dde4cedc57243e725e18f7212b86144428a5a0b2bb0f0269b6fbaffc316f49c,
                0x0716628c2ca647b44d01e95683a1b335bd570115ecb5d6a343768ebdace892ab
            ],
            [
                0x1be461c5e59f3362e16b7a9db5acbc4c46ac4ec535433d36384b79f699ae53c8,
                0x110a0c70abbfc0d96fc301f291364de507e85fb7695533cc46eb371c69f6e291
            ]
        ];

        uint[2] memory c = [
            0x02d2540b7b8397d9be48852d40306ee139f05873aa61bc5258070941fa71f95a,
            0x14592a1fb508872482534cd3993681180a656feff84a4f3d9ccc21d2afd0dae5
        ];

        uint256[1] memory input = [uint256(0x01)];

        // Now you can call the function with these packed arguments

        flappyQF.submitGameProof(projectId, a, b, c, input);
        console2.log("Game proof submitted successfully");

        vm.stopBroadcast();
    }
}
