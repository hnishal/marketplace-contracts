const { upgrades, ethers } = require("hardhat");


async function main() {
  const marketFactory = await ethers.getContractFactory("NFTMarket");
  const marketplace = await upgrades.deployProxy(marketFactory, { initializer: 'initialize', kind: 'uups' });
  await marketplace.deployed();
  console.log("Token address:", marketplace.address);
  const currentImplemetation = await upgrades.erc1967.getImplementationAddress(marketplace.address);
  console.log("Current implementation address:", currentImplemetation);
  const adminAddress = await upgrades.erc1967.getAdminAddress(marketplace.address);
  console.log("Admin: ", adminAddress);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
