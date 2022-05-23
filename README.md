# Cheap DAO Smart Contracts

Steps to setup the contracts:-

- install the dependencies using `yarn install`
- Copy the .env.template to .env, and update the values in the .env file.
- Deploy the contracts using the following command:

```bash
npx hardhat run scripts/deployContracts.js --network polygon
npx hardhat run scripts/deployContracts.js --network mainnet 
```

- Connect both treasury and governance contracts using the following command:

```bash
npx hardhat run scripts/setUpFxTunnel.js --network polygon
npx hardhat run scripts/setUpFxTunnel.js --network mainnet 
```
