const hre = require("hardhat");
const fs = require("fs");

async function main() {
    let GovernorConfig, TreasuryConfig;
    const networkName = hre.network.name;
    try {
        GovernorConfig = fs.existsSync("./contractConfig/Governor.json") ? JSON.parse(fs.readFileSync("./contractConfig/Governor.json")) : null;
        if (!GovernorConfig) throw "Config not found";
    } catch (err) {
        console.error("Governor Config not found");
        return;
    }
    try {
        TreasuryConfig = fs.existsSync("./contractConfig/Treasury.json") ? JSON.parse(fs.readFileSync("./contractConfig/Treasury.json")) : null;
        if (!TreasuryConfig) throw "Config not found";
    } catch (err) {
        console.error("Treasury Config not found");
        return;
    }
    if (networkName === "mumbai" || networkName === "polygon") {
        const Governor = await hre.ethers.getContractFactory("Governor");
        const governor = Governor.attach(GovernorConfig.address);
        await governor.setFxRootTunnel(TreasuryConfig.address);
        console.log("Updated the fx tunnel addresses on child contracts");
    } else if (networkName === "goerli" || networkName === "mainnet") {
        const Treasury = await hre.ethers.getContractFactory("Treasury");
        const treasury = Treasury.attach(TreasuryConfig.address);
        await treasury.setFxChildTunnel(GovernorConfig.address);
        console.log("Updated the fx tunnel addresses on root contracts");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });