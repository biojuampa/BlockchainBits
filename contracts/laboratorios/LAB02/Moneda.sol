// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Moneda {

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() payable {}

    /// @param _guess es un boolean que debe ser true o false
    function flip(bool _guess) public payable {
        require(msg.value == 1 ether, "Not enough Ether");

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        );

        /**
         * coinFlip puede tener solo dos valores: 0 o 1
         * Si randomNumber es mayor a FACTOR, coinFlip = 1
         * Si randomNumber es menor a FACTOR, coinFlip = 0
         */
        uint256 coinFlip = randomNumber / FACTOR;
        bool guess = coinFlip == 1 ? true : false;

        if (_guess == guess) {
            // ganaste
            payable(msg.sender).transfer(2 ether);
        }
    }

}