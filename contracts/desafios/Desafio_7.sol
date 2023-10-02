// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
REPETIBLE CON LÍMITE, PREMIO POR REFERIDO

* El usuario puede participar en el airdrop una vez por día hasta un límite de 10 veces
* Si un usuario participa del airdrop a raíz de haber sido referido, el que refirió gana 3 días adicionales para poder participar
* El contrato Airdrop mantiene los tokens para repartir (no llama al `mint` )
* El contrato Airdrop tiene que verificar que el `totalSupply`  del token no sobrepase el millón
* El método `participateInAirdrop` le permite participar por un número random de tokens de 1000 - 5000 tokens
*/

interface IMiPrimerTKN {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropTwo is Pausable, AccessControl {
    // instanciamos el token en el contrato
    IMiPrimerTKN miPrimerToken;

    constructor(address _tokenAddress) {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct Participante {
        address cuentaParticipante;
        uint participaciones;
        uint limiteParticipaciones;
        uint ultimaVezParticipado;
    }

    mapping (address => Participante) public participantes;

    modifier quedanIntentos() {
        Participante storage participante = participantes[msg.sender];

        if (participante.cuentaParticipante == address(0)) {
            participante.cuentaParticipante = msg.sender;
            participante.limiteParticipaciones = 10;
        }

        require(
            participante.participaciones < participante.limiteParticipaciones,
            "Llegaste limite de participaciones"
        );       

        _;
    }
    
    modifier yaPasoUnDia () {
        require(
            (participantes[msg.sender].ultimaVezParticipado + 1 days) < block.timestamp,
            "Ya participaste en el ultimo dia"
        );

        _;
    }

    modifier noAutoreferido(address _account) {
        require(
            msg.sender != _account,
            "No puede autoreferirse"
        );


        _;
    }

    function participateInAirdrop() public
        quedanIntentos
        yaPasoUnDia
    {

        // Número aleatorio de tokens a recibir
        uint tokensaRecibir = _getRadomNumber10005000();

        // Si el contrato tiene suficientes tokens
        require(
            miPrimerToken.balanceOf(address(this)) >= tokensaRecibir,
            "El contrato Airdrop no tiene tokens suficientes"
        );

        // Le transfiero los tokens al usuario
        bool succcess = miPrimerToken.transfer(msg.sender, tokensaRecibir);
        
        // Transferencia de tokens existosa
        if (succcess) {
            participantes[msg.sender].participaciones += 1;
            participantes[msg.sender].ultimaVezParticipado = block.timestamp;
        } else {
            revert("Hubo un error transfiriendo los tokens");
        }
        
    }

    function participateInAirdrop(address _elQueRefirio) public
        noAutoreferido(_elQueRefirio)
    {
        participantes[_elQueRefirio].limiteParticipaciones = 13;
        participateInAirdrop();
    }

    ///////////////////////////////////////////////////////////////
    ////                     HELPER FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function _getRadomNumber10005000() internal view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                4000) +
            1000 +
            1;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function transferTokensFromSmartContract()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        miPrimerToken.transfer(
            msg.sender,
            miPrimerToken.balanceOf(address(this))
        );
    }
}
