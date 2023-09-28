// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IUSDCoin {
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
    
    function decimals() external pure returns (uint8);

    function allowance(address owner,address spender) external view returns (uint);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract MiTokenJPCamussi is ERC20, ERC20Burnable {
    IUSDCoin usdc;

    mapping (address => bool) public blackList;

    uint public ratio = 50; // 1 USDC = 50 MTLMRR

    constructor(address _usdcAddress) ERC20("Mi Token JPC", "JPCTKN") {
        usdc = IUSDCoin(_usdcAddress);
    }

    // function mint(address to, uint256 amount) public {
    //     _mint(to, amount);
    // }

    function meterEnListaNegra(address _account) public {
        blackList[_account] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, amount);
        // Sugerencia de openzeppelin
        require(from != address(0) || to != address(0), "Ambos address no pueden ser 0x00 a la vez");
        // Valido que no esté el usuario en la lista negra
        require(!blackList[msg.sender], "La cuenta se encuentra bloqueada");
    }

    function _efectuarTransferYCompra(
        uint256 _cantidadDeUsdc,
        uint256 _cantidadTokens
    ) internal {
        uint256 _allowance = usdc.allowance(msg.sender, address(this));
        require(_allowance >= _cantidadDeUsdc, "Incorrecto permiso de USDC");

        _beforeTokenTransfer(msg.sender, address(this), _cantidadDeUsdc);
        usdc.transferFrom(msg.sender, address(this), _cantidadDeUsdc);

        _beforeTokenTransfer(address(0), msg.sender, _cantidadTokens);
        _mint(msg.sender, _cantidadTokens);
    }    

    // Sé cuantos tokens MTLMRR deseo comprar
    // Calcula la cantidad de USDC a entregar
    function comprarTokensExactoPorUsdc(uint256 _cantidadTokens) public {
        // cantidadTokens viene con 18 decimales
        uint amountUsdc = _cantidadTokens / ratio;

        // le quitamos 12 decimales
        amountUsdc = amountUsdc / (10 ** (decimals() - usdc.decimals()));

        // le cargamos el fee del 30%
        amountUsdc = amountUsdc * 13 / 10;

        _efectuarTransferYCompra(amountUsdc, _cantidadTokens);
    }

    // Sé cuantos USDC voy a entregar
    // Calcula la cantidad de tokens MTLMRR a recibir
    function comprarTokensPorUsdcExacto(uint256 _cantidadDeUsdc) public {
        // usdc viene con 6 decimales
        uint256 cantidadTokens = _cantidadDeUsdc * ratio;

        // Fee del 30%
        cantidadTokens = cantidadTokens * 7 / 10;

        // agrega los 12 decimales
        // decimals() == 18
        // usdc.decimals() == 6
        cantidadTokens = cantidadTokens * 10 ** (decimals() - usdc.decimals());

        _efectuarTransferYCompra(_cantidadDeUsdc, cantidadTokens);
    }

    function burnTokensExacto(uint256 cantidadTokens) public {
        // cantidadTokens viene con 18 decimales
        // Se convierte a USDC con el ratio
        // Se cobra un fee del 10%
        uint256 usdcDevolver = cantidadTokens / 10 / ratio;

        // Se le quitan 12 decimales
        usdcDevolver = usdcDevolver / (10 ** (decimals() - usdc.decimals()));

        burn(cantidadTokens);
        // Efectúa la devolución de USDC al usuario
        usdc.transfer(msg.sender, usdcDevolver);
    }
}
