require("@nomicfoundation/hardhat-toolbox");
require("@xyrusworx/hardhat-solidity-json");

const { vars } = require("hardhat/config");
const privateKey = vars.get("PRIV_KEY");
const etherscanApi = vars.get("ETHERSCAN_API_KEY");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "hardhat",
  ignition: {
    requiredConfirmations: 1
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },

  networks: {
	hardhat: { chainId: 31337 },
	shimmerEvmTestnet: {
	  chainId: 1073,
	  url: "https://json-rpc.evm.testnet.shimmer.network",
	  accounts: [privateKey],
	},
	shimmerEvmMainnet: {
	  chainId: 148,
	  url: "https://json-rpc.evm.shimmer.network",
	  accounts: [privateKey],
	},  
	iotaEvmTestnet: {
	  chainId: 1075,
	  url: "https://json-rpc.evm.testnet.iotaledger.net",
	  accounts: [privateKey],
	},
	iotaEvmMainnet: {
	  chainId: 8822,
	  url: "https://json-rpc.evm.iotaledger.net",
	  accounts: [privateKey],
	},
  },
};
