require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.3",
  networks: {
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/3KSgF27hgFzJh0U9CGrP6J_OWTqZ-B78',
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API
  }
};
