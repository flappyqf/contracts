#!/bin/bash

source .env

CONTRACT_ADDRESS="0x8E5a7636320b9aEcB5B675839B97c5cDEF96478B"

for i in {0..7}
do
    IPFS_HASH="QmHash${i}"  # Replace with actual IPFS hashes
    cast send $CONTRACT_ADDRESS "submitProject(string,address)" "test" $CONTRACT_ADDRESS --rpc-url $SEPOLIA_RPC_URL --private-key $PRIV_KEY
    echo "Submitted project $i"
    sleep 5  # Wait 5 seconds between transactions
done

for i in {0..7}
do
    cast send $CONTRACT_ADDRESS "acceptProject(uint256)" $i --rpc-url $SEPOLIA_RPC_URL --private-key $PRIV_KEY
    echo "Accepted project $i"
    sleep 5  # Wait 5 seconds between transactions
done
    

cast send $CONTRACT_ADDRESS "initiateMatching()" --rpc-url $SEPOLIA_RPC_URL --private-key $PRIV_KEY
