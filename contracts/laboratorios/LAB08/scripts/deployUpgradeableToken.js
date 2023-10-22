const { ethers, upgrades } = require("hardhat");


// Address del Contrato Proxy: 0x194C67660eC1E1E95C146AF7e5BB78094d24Bb4E
// Address de la primer Impl:  0x894b1c24B94B7ac602D1883EF90dF041838f5f05
// Address de la segunda Impl: 0x460490e4Fdc0F0BB269A2b5F66c7Beb43c7E3366
async function main() {
    // obtener el código del contrato
    var UpgradeableToken = await ethers.getContractFactory("JPCTokenUpgradeable");
    
    // publicar el proxy
    var upgradeableToken = await upgrades.deployProxy(
        UpgradeableToken,   // código del contrato
        [],                 // atributos del inicializador
        {kind: "uups"}      // tipo de contrato actualizable
    );

    // esperar a que se confirme el contrato - 5 confirmaciones
    var tx = await upgradeableToken.waitForDeployment();
    await tx.deploymentTransaction().wait(5);

    // obtenemos el address de implementación
    var implementationAddr = await upgrades
        .erc1967
        .getImplementationAddress(await upgradeableToken.getAddress())
    ;
    
    console.log(`Address del  Proxy -> ${await upgradeableToken.getAddress()}`);
    console.log(`Address de la Impl -> ${implementationAddr}`);

    // hacemos la verificación del address de implementación
    await hre.run("verify:verify", {
        address: implementationAddr,
        constructorArguments: [],
    });
}

async function upgrade() {
    const ProxyAddress = "0x194C67660eC1E1E95C146AF7e5BB78094d24Bb4E";
    var JPCTokenUpgradeableV2 = await ethers
        .getContractFactory("JPCTokenUpgradeableV2")
    ;

    var jpcTokenUpgradeableV2 = await upgrades.upgradeProxy(
        ProxyAddress,
        JPCTokenUpgradeableV2
    );

    // aquí debería esperar unas confirmaciones

    var implementationAddrV2 = await upgrades
        .erc1967
        .getImplementationAddress(ProxyAddress)
    ;

    console.log(`Address Proxy:  ${ProxyAddress}`);
    console.log(`Address ImplV2: ${implementationAddrV2}`);

    await hre.run("verify:verify", {
        address: implementationAddrV2,
        constructorArguments: [],
    });
}

// main().catch(error => {
//     console.log(error);
//     process.exitCode = 1;
// });

upgrade().catch(error => {
    console.log(error);
    process.exitCode = 1;
});
