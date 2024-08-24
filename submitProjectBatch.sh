#!/bin/bash

source .env

CONTRACT_ADDRESS="0x4A0AB940534DF591dD27e374cC90B46666e05911"

for i in {1..8}
do
    IPFS_HASH="QmHash${i}"  # Replace with actual IPFS hashes
    cast send $CONTRACT_ADDRESS "submitProject(string)" "test" --rpc-url $SEPOLIA_RPC_URL --private-key $PRIV_KEY
    echo "Submitted project $i"
    sleep 5  # Wait 5 seconds between transactions
done