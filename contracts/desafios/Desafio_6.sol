// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
LISTA BLANCA Y NÚMERO ALEATORIO

* Se necesita ser parte de la lista blanca para poder participar del Airdrop - done
* Los participantes podrán solicitar un número rándom de tokens de 1-1000 tokens
* Total de tokens a repartir es 10 millones
* Solo se podrá participar una sola vez
* Si el usuario permite que el contrato airdrop queme 10 tokens, el usuario puede volver a participar una vez más
* El contrato Airdrop tiene el privilegio de poder llamar `mint` del token
* El contrato Airdrop tiene el privilegio de poder llamar `burn` del token
*/

interface IMiPrimerTKN {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropOne is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant totalAirdropMax = 10 ** 6 * 10 ** 18;
    uint256 public constant quemaTokensParticipar = 10 * 10 ** 18;

    uint256 airdropGivenSoFar;

    address public miPrimerTokenAdd;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public haSolicitado;

    constructor(address _tokenAddress) {
        miPrimerTokenAdd = _tokenAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function participateInAirdrop() public whenNotPaused {
        // lista blanca

        // ya solicitó tokens

        // pedir número random de tokens
        uint256 tokensToReceive = _getRadomNumberBelow1000();

        // verificar que no se exceda el total de tokens a repartir

        // actualizar el conteo de tokens repartidos
        // marcar que ya ha participado

        // transferir los tokens
    }

    function quemarMisTokensParaParticipar() public whenNotPaused {
        // verificar que el usuario aun no ha participado
        // Verificar si el que llama tiene suficientes tokens
        // quemar los tokens
        // dar otro chance
    }

    ///////////////////////////////////////////////////////////////
    ////                     HELPER FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function addToWhiteList(
        address _account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteList[_account] = true;
    }

    function removeFromWhitelist(
        address _account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteList[_account] = false;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _getRadomNumberBelow1000() internal view returns (uint256) {
        uint256 random = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 1000) + 1;
        return random * 10 ** 18;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerTokenAdd = _tokenAddress;
    }
}
