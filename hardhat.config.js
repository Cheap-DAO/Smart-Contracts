require("dotenv").config();
require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.9",
  networks: {
    mumbai: {
      accounts: [process.env.PRIVATE_KEY],
      url: process.env.MUMBAI_RPC_URL,
      saveDeployments: true
    },
    goerli: {
      accounts: [process.env.PRIVATE_KEY],
      url: process.env.GOERLI_RPC_URL,
      saveDeployments: true
    },
    polygon: {
      accounts: [process.env.PRIVATE_KEY],
      url: process.env.POLYGON_RPC_URL,
      saveDeployments: true
    },
    mainnet: {
      accounts: [process.env.PRIVATE_KEY],
      url: process.env.MAINNET_RPC_URL,
      saveDeployments: true
    }
  }
};
