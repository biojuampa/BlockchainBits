// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenJPC20Permit is ERC20, ERC20Permit {
    constructor()
        ERC20("JPC Permit", "JPCTKN20PER")
        ERC20Permit("JPC Permit")
    {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}