const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Lock", function () {
  let proxy, implementationAddr, nftContract;
  let deployer, account1, account2;
  let addr = [];

  before(async function () {
    [deployer, account1, account2, ...addr] = await ethers.getSigners();

    const marketFactory = await ethers.getContractFactory("NFTMarket");
    const marketplace = await upgrades.deployProxy(marketFactory, { initializer: 'initialize', kind: 'uups' });
    await marketplace.deployed();

    proxy = marketplace;
    console.log("Proxy contract deployed at: ", proxy.address);

    implementationAddr = await upgrades.erc1967.getImplementationAddress(proxy.address);
    console.log("Implementation address:", implementationAddr);

    const contractFactory = await ethers.getContractFactory("TestNft");
    nftContract = await contractFactory.deploy();
    await nftContract.deployed();

    console.log("nftContract deployed at: ", nftContract.address);

  })

  describe("Mint Nfts", function () {
    it("should mint some nfts", async () => {
      await nftContract.safeMint(account1.address);
      await nftContract.safeMint(account2.address);
      await nftContract.safeMint(account2.address);
      expect(await nftContract.balanceOf(account1.address)).to.equal(1);
      expect(await nftContract.balanceOf(account2.address)).to.equal(2);
    })
  });

  describe("marketplace test", function () {
    it("should put an nft on sale", async () => {
      // granting minter role to account 1 and approving contract
      await proxy.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', account1.address);

      //aproving proxy contract
      await nftContract.connect(account1).approve(proxy.address, 0);

      // creating list item
      await proxy.connect(account1).createMarketItem(nftContract.address, 0, ethers.utils.parseUnits("0.11", "ether"));

      //fetching data
      const saledata = await proxy.getItem(1);
      console.log("item info: ", saledata);
      expect(saledata.tokenId).to.equal(0);
      expect(saledata.seller).to.equal(account1.address);
      expect(saledata.price).to.equal(ethers.utils.parseUnits("0.11", "ether"));
    })
  })
});
