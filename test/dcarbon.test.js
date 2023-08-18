const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DCarbon", () => {
  it("DCarbon_Init", async function () {
    const signers = await ethers.getSigners();
    const DCarbonFactory = await ethers.getContractFactory("DCarbon");
    const ProxyFactory = await ethers.getContractFactory("Proxy");

    const dcarbon = await DCarbonFactory.deploy();
    await dcarbon.deployed();
    const proxy = await ProxyFactory.deploy(dcarbon.address);
    const proxyDcarbon = DCarbonFactory.attach(proxy.address);
    await proxyDcarbon.initialize(
      [signers[0].address, signers[1].address, signers[2].address],
      [100 * 1e9, 200 * 1e9, 300 * 1e9]
    );

    expect(await proxyDcarbon.name()).equal("DCarbon");
    expect(await proxyDcarbon.symbol()).equal("DCB");
    expect(await proxyDcarbon.owner()).equal(signers[0].address);
  });
});
