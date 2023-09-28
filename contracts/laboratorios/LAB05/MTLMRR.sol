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

contract MiTokenLeeMarreros is ERC20, ERC20Burnable {
    IUSDCoin usdc;

    uint public ratio = 50; // 1 USDC = 50 MTLMRR

    constructor(address _usdcAddress) ERC20("Mi Token Lee Marreros", "MTLMRR") {
        usdc = IUSDCoin(_usdcAddress);
    }

    // function mint(address to, uint256 amount) public {
    //     _mint(to, amount);
    // }

    function _efectuarTransferYCompra(
        uint256 _cantidadDeUsdc,
        uint256 _cantidadTokens
    ) internal {
        uint256 _allowance = usdc.allowance(msg.sender, address(this));
        require(_allowance >= _cantidadDeUsdc, "Incorrecto permiso de USDC");

        usdc.transferFrom(msg.sender, address(this), _cantidadDeUsdc);
        _mint(msg.sender, _cantidadTokens);
    }    

    // Sé cuantos tokens MTLMRR deseo comprar
    // Calcula la cantidad de USDC a entregar
    function comprarTokensExactoPorUsdc(uint256 _cantidadTokens) public {
        // cantidadTokens viene con 18 decimales
        uint amountUsdc = _cantidadTokens / ratio;
        // le quitamos 12 decimales
        amountUsdc = amountUsdc / (10 ** (decimals() - usdc.decimals()));

        _efectuarTransferYCompra(amountUsdc, _cantidadTokens);
    }

    // Sé cuantos USDC voy a entregar
    // Calcula la cantidad de tokens MTLMRR a recibir
    function comprarTokensPorUsdcExacto(uint256 _cantidadDeUsdc) public {
        // usdc viene con 6 decimales
        uint cantidadTokens = _cantidadDeUsdc * ratio;
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
