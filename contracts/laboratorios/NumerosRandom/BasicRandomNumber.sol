// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract BasicRandomNumber {
    // uint256 public randomNumber;

    function requestRandomWords() external view returns (uint256) {
        // randomNumber = uint256(
        return uint256(    
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        );
    }
}