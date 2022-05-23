const hre = require("hardhat");
const fs = require("fs");

async function main() {
    const networkName = hre.network.name;
    if (networkName === "mumbai" || networkName === "polygon") {
        let _fxChild;
        if (networkName === "mumbai") {
            _fxChild = "0xCf73231F28B7331BBe3124B907840A94851f9f11";
        } else {
            _fxChild = "0x8397259c983751DAf40400790063935a11afa28a";
        }
        const Token = await hre.ethers.getContractFactory("GovernanceToken");
        const token = await Token.deploy();
        await token.deployed();
        const Governor = await hre.ethers.getContractFactory("Governor");
        const governor = await Governor.deploy("Governor Demo", token.address, _fxChild);
        await governor.deployed();
        const tokenConfig = {
            address: token.address,
            abi: JSON.parse(token.interface.format('json'))
        }
        const governorConfig = {
            address: governor.address,
            abi: JSON.parse(governor.interface.format('json'))
        }
        fs.writeFileSync("contractConfig/Token.json", JSON.stringify(tokenConfig));
        fs.writeFileSync("contractConfig/Governor.json", JSON.stringify(governorConfig));
    } else if (networkName === "goerli" || networkName === "mainnet") {
        let _checkpointManager, _fxRoot;
        if (networkName === "goerli") {
            _checkpointManager = "0x2890bA17EfE978480615e330ecB65333b880928e";
            _fxRoot = "0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA";
        } else {
            _checkpointManager = "0x86e4dc95c7fbdbf52e33d563bbdb00823894c287";
            _fxRoot = "0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2";
        }
        const Treasury = await hre.ethers.getContractFactory("Treasury");
        const treasury = await Treasury.deploy(_checkpointManager, _fxRoot);
        await treasury.deployed();
        const treasuryConfig = {
            address: treasury.address,
            abi: JSON.parse(treasury.interface.format('json'))
        }
        fs.writeFileSync("contractConfig/Treasury.json", JSON.stringify(treasuryConfig));
    } else {
        console.error("Network not supported");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });