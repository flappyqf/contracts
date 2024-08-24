#!/bin/bash

source .env

CONTRACT_ADDRESS="0x0BaA3846bB2793e17f72a17A96916b5F26953e0e"

for i in {0..7}
do
    IPFS_HASH="QmHash${i}"  # Replace with actual IPFS hashes
    cast send $CONTRACT_ADDRESS "submitProject(string)" "test" --rpc-url $SEPOLIA_RPC_URL --private-key $PRIV_KEY
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
