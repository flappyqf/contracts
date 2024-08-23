// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import {Script, console2} from "forge-std/Script.sol";

// contract DeployScript is Script {
//     function run() external {
//         uint256 privKey = vm.envUint("PRIV_KEY");
//         address deployer = vm.rememberKey(privKey);

//         console2.log("Deployer: ", deployer);
//         console2.log("Deployer Nonce: ", vm.getNonce(deployer));

//         vm.startBroadcast(deployer);

//         // Deploy MultiSigWalletFactory
//         MultiSigWalletFactory factory = new MultiSigWalletFactory();
//         console2.log("MultiSigWalletFactory deployed at: ", address(factory));

//         // Create a new MultiSigWallet using the factory
//         address[] memory owners = new address[](3);
//         owners[0] = deployer;
//         owners[1] = address(0x1111111111111111111111111111111111111111);
//         owners[2] = address(0x2222222222222222222222222222222222222222);
//         uint256 required = 2;

//         address newWalletAddress = factory.createWallet(owners, required);
//         MultiSigWallet newWallet = MultiSigWallet(payable(newWalletAddress));
//         console2.log("New MultiSigWallet deployed at: ", newWalletAddress);

//         // Interact with the new wallet
//         uint256 depositAmount = 0.0001 ether;
//         (bool success, ) = newWalletAddress.call{value: depositAmount}("");
//         require(success, "Deposit failed");
//         console2.log("Deposited ", depositAmount, " wei to the wallet");

//         // Submit a transaction
//         address recipient = address(0x3333333333333333333333333333333333333333);
//         uint256 value = 0.0001 ether;
//         bytes memory data = "";
//         uint256 txIndex = newWallet.submitTransaction(recipient, value, data);
//         console2.log("Submitted transaction with index: ", txIndex);

//         // Confirm the transaction
//         newWallet.confirmTransaction(txIndex);
//         console2.log("Confirmed transaction with index: ", txIndex);

//         vm.stopBroadcast();

//         // Log final state
//         console2.log("Wallet balance: ", address(newWallet).balance);
//         console2.log("Transaction count: ", newWallet.getTransactionCount());
//     }
// }
