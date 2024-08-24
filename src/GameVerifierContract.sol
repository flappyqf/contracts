// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GameVerifier.sol"; // This is the Solidity verifier exported from snarkjs

contract GameProof {
    GameVerifier public verifier;

    constructor(address _verifierAddress) {
        verifier = GameVerifier(_verifierAddress);
    }

    function verifyGameProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public view returns (bool) {
        uint256[24] memory _proof;

        // Pack the proof elements into the expected format
        _proof[0] = a[0];
        _proof[1] = a[1];
        _proof[2] = b[0][0];
        _proof[3] = b[0][1];
        _proof[4] = b[1][0];
        _proof[5] = b[1][1];
        _proof[6] = c[0];   
        _proof[7] = c[1];

        // Fill the rest of _proof with zeros if necessary
        for (uint i = 8; i < 24; i++) {
            _proof[i] = 0;
        }

        return verifier.verifyProof(_proof, input);
    }
}
