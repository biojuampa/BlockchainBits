// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/** CUASI SUBASTA INGLESA
 *
 * Descripción:
 * Tienen la tarea de crear un contrato inteligente que permita crear subastas Inglesas (English auction).
 * Se paga 1 Ether para crear una subasta y se debe especificar su hora de inicio y finalización.
 * Los ofertantes envian sus ofertas a la subasta que ellos deseen durante el tiempo que la subasta esté abierta.
 * Cada subasta tiene un ID único que permite a los ofertantes identificar la subasta a la que desean ofertar.
 * Los ofertantes para poder proponer su oferta envían Ether al contrato (llamando al método 'proponerOferta' o enviando directamente).
 * Las ofertas deben ser mayores a la oferta más alta actual para una subasta en particular.
 * Si se realiza una oferta dentro de los 5 minutos finales de la subasta, el tiempo de finalización se extiende en 5 minutos
 * Una vez que el tiempo de la subasta se cumple, cualquier puede llamar al método 'finalizarSubasta' para finalizar la subasta.
 * Cuando finaliza la subasta, el ganador recupera su oferta y se lleva el 1 Ether depositado por el creador.
 * Cuando finaliza la subasta se emite un evento con el ganador (address)
 * Las personas que no ganaron la subasta pueden recuperar su oferta después de que finalice la subasta
 *
 * ¿Qué es una subasta Inglesa?
 * En una subasta inglesa el precio comienza bajo y los postores pujan el precio haciendo ofertas.
 * Cuando se cierra la subasta, se emite un evento con el mejor postor.
 *
 * Métodos a implementar:
 * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
 *      * Crea un ID único del typo bytes32 para la subasta y lo guarda en la lista de subastas activas
 *      * Permite a cualquier usuario crear una subasta pagando 1 Ether
 *          - Error en caso el usuario no envíe 1 Ether: CantidadIncorrectaEth();
 *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio
 *          - Error en caso el tiempo de finalización sea mayo al tiempo de inicio: TiempoInvalido();
 *      * Disparar un evento llamado 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address)
 *
 * - El método 'proponerOferta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Usando el ID de una subasta (_auctionId), el ofertante propone una oferta y envía Ether al contrato
 *          - Error si la oferta no es mayor a la oferta más alta actual: OfertaInvalida();
 *      * Solo es llamado durante el tiempo de la subasta (entre el inicio y el final)
 *          - Error si la subasta no está en progreso: FueraDeTiempo();
 *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta
 *      * Guarda la cantidad de Ether enviado por el postor para luego poder recuperar su oferta en caso no gane la subasta
 *      * Añade 5 minutos al tiempo de finalización de la subasta si la oferta se realizó dentro de los últimos 5 minutos
 *      Nota: Cuando se hace una oferta, incluye el Ether enviado anteriormente por el ofertante
 *
 * - El método 'finalizarSubasta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Es llamado luego del tiempo de finalización de la subasta usando su ID (_auctionId)
 *          - Error si la subasta aún no termina: SubastaEnMarcha();
 *      * Elimina el ID de la subasta (_auctionId) de la lista de subastas activas
 *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta
 *      * Añade 1 Ether al balance del ganador de la subasta para que éste lo puedo retirar después
 *
 * - El método 'recuperarOferta(bytes32 _auctionId)':
 *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta)
 *      * Verifica que la subasta haya finalizado
 *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante
 *
 * - El método 'verSubastasActivas() returns(bytes32[])':
 *      * Devuelve la lista de subastas activas en un array
 *
 * Para correr el test de este contrato:
 * $ npx hardhat test test/EjercicioIntegrador_4.ts
 */

contract Desafio_4 {
    event SubastaCreada(bytes32 indexed _auctionId, address indexed _creator);
    event OfertaPropuesta(address indexed _bidder, uint256 _bid);
    event SubastaFinalizada(address indexed _winner, uint256 _bid);

    error CantidadIncorrectaEth();
    error TiempoInvalido();
    error SubastaInexistente();
    error FueraDeTiempo();
    error OfertaInvalida();
    error SubastaEnMarcha();

    // Un ether
    uint constant ETH = 10**18; 

    struct Auction {
        bytes32 auctionID;
        bool finalized;
        uint startTime;
        uint endTime;
        mapping(address => uint) offers;
        uint highestBid;        // siempre será la última oferta
        address highestBidder;  // siempre será el último oferente
    }
    
    bytes32[] subastasActivas;
    mapping (bytes32 => uint) indiceSubastasActivas; // indice + 1 (desplazo el index para poder controlar el address(0))

    mapping(bytes32 => Auction) subastas;

    
    modifier siSubastaExiste(bytes32 _auctionID) {
        if (subastas[_auctionID].auctionID == 0)
            revert SubastaInexistente();
        _;
    }

    modifier enTiempo(bytes32 _auctionID) {

        uint startTime = subastas[_auctionID].startTime;
        uint endTime = subastas[_auctionID].endTime;
        uint actual = block.timestamp;

        if (startTime > actual || actual > endTime)
            revert FueraDeTiempo();

        _;
    }

    modifier siSubastaTerminada(bytes32 _auctionID) {
        if (subastas[_auctionID].endTime > block.timestamp)
            revert SubastaEnMarcha();
        _;
    }

    modifier siSubastaFinalizada(bytes32 _auctionID) {
        if (!subastas[_auctionID].finalized)
            revert SubastaEnMarcha();
        _;
    }

    modifier siSubastaNoFinalizada(bytes32 _auctionID) {
        if (subastas[_auctionID].finalized)
            revert SubastaInexistente();
        _;
    }

    // agrego una subasta al array de subastas (y su mapa de índices)
    function agregarSubasta(bytes32 _auctionID) public {
        require(indiceSubastasActivas[_auctionID] == 0, "La subasta ya existe");
        
        subastasActivas.push(_auctionID);
        indiceSubastasActivas[_auctionID] = subastasActivas.length; // index + 1
    }

    // quito una subasta del array de subastas (y de su mapa de índices)
    function quitarSubasta(bytes32 _auctionID) public {
        require(indiceSubastasActivas[_auctionID] != 0, "La subasta NO existe");

        uint index = indiceSubastasActivas[_auctionID] - 1; // índice de la subasta a quitar en el vector 
        uint lastIndex = subastasActivas.length - 1;        // último íncide del vector de subastas activas

        bytes32 auctionToMove = subastasActivas[lastIndex];
        subastasActivas[index] = auctionToMove;
        subastasActivas.pop();

        indiceSubastasActivas[auctionToMove] = index + 1;
        delete indiceSubastasActivas[_auctionID];
    }

    function creaSubasta(uint256 _startTime, uint256 _endTime) public payable {
        if (_endTime < _startTime) {
            revert TiempoInvalido();
        }
        if (msg.value != ETH) {
            revert CantidadIncorrectaEth();
        }

        bytes32 _auctionId = _createId(_startTime, _endTime);

        agregarSubasta(_auctionId);

        Auction storage auction = subastas[_auctionId];
        auction.auctionID = _auctionId;
        auction.startTime = _startTime;
        auction.endTime = _endTime;

        emit SubastaCreada(_auctionId, msg.sender);
    }

    function proponerOferta(bytes32 _auctionId) public payable
        siSubastaExiste(_auctionId)
        enTiempo(_auctionId)
    {
        Auction storage auction = subastas[_auctionId];

        // Del enunciado entiendo que la oferta es las suma de todo el dinero
        // ya enviado por el postor (lo que realmente facilita el trabajo)
        uint offer = auction.offers[msg.sender] + msg.value;
        if (offer < auction.highestBid) {
            revert OfertaInvalida();
        }

        // mejor oferta
        auction.highestBid = offer;
        // mejor postor
        auction.highestBidder = msg.sender;

        // guardo el total ofertado por el participante para saber cuánto devolverle
        auction.offers[msg.sender] = offer;

        // extiendo el tiempo de la subasta
        uint tiempoRestante = auction.endTime - block.timestamp;
        if (tiempoRestante < 5 minutes)
            auction.endTime += 5 minutes;

        emit OfertaPropuesta(msg.sender, auction.offers[msg.sender]);
    
    }

    function finalizarSubasta(bytes32 _auctionId) public
        siSubastaExiste(_auctionId)
        siSubastaTerminada(_auctionId)
        siSubastaNoFinalizada(_auctionId)
    {
        Auction storage auction = subastas[_auctionId];

        // Eliminar la subasta de la lista de subastas activas
        quitarSubasta(_auctionId);

        // Premiar al mejor postor con 1 ether
        auction.offers[auction.highestBidder] += ETH;

        // Finalizar subasta
        auction.finalized = true;

        emit SubastaFinalizada(auction.highestBidder, auction.highestBid);
    }

    function recuperarOferta(bytes32 _auctionId) public
        siSubastaExiste(_auctionId)
        siSubastaFinalizada(_auctionId)
    {
        uint amount = subastas[_auctionId].offers[msg.sender];
        payable(msg.sender).transfer(amount);
    }

    function verSubastasActivas() public view returns (bytes32[] memory) {
        return subastasActivas;
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////   INTERNAL METHODS  ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function _createId(
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _startTime,
                    _endTime,
                    msg.sender,
                    block.timestamp
                )
            );
    }
}
