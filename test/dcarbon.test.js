const { expect } = require("chai");
const { ethers } = require("hardhat");

async function expectRevert(label, reason, fnPromise) {
  try {
    await fnPromise;
    throw new Error(`${label} was success (not expect)`);
  } catch (err) {
    if (reason) {
      expect(reason).to.equal(reason);
    }
    // console.log(`${label} error: ${err}`);
    // console.log(`${label} error: ${JSON.stringify(err)}`);
  }
}

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
    console.log("DCarbon init success: ", proxy.address);
    console.log("Owner was set: ", await proxyDcarbon.owner());
  });
  it("Upgrade", async function () {
    const DCarbonFactory2 = await ethers.getContractFactory("DCarbon2");
    const DCarbonFactory = await ethers.getContractFactory("DCarbon");
    const ProxyFactory = await ethers.getContractFactory("Proxy");
    var x = ethers.getContractFactory("Proxy");
    var y = await x;
    const dcarbon2 = await DCarbonFactory2.deploy();
    await dcarbon2.deployed();
    const signers = await ethers.getSigners();
    const ownerInit = [
      signers[0].address,
      signers[1].address,
      signers[2].address,
    ];
    const balanceInit = [
      "0x056bc75e2d63100000",
      "0x0ad78ebc5ac6200000",
      "0x1043561a8829300000",
    ];
    const dcarbon = await DCarbonFactory.deploy();
    await dcarbon.deployed();
    const proxy = await ProxyFactory.deploy(dcarbon.address);
    var proxyDcarbon = DCarbonFactory.attach(proxy.address);
    await proxyDcarbon.initialize(ownerInit, balanceInit);
    expect(await proxyDcarbon.name()).equal("DCarbon");
    // await expectRevert(
    //   "Initialize ",
    //   proxyDcarbon.initialize(ownerInit, balanceInit)
    // );
    await expect(
      proxyDcarbon.initialize(ownerInit, balanceInit)
    ).to.be.revertedWith("Initializable: contract is already initialized");
    expect(await proxyDcarbon.owner()).to.equal(ownerInit[0]);
    for (var i = 0; i < ownerInit.length; i++) {
      expect(
        (await proxyDcarbon.balanceOf(ownerInit[i])).toHexString()
      ).to.equal(balanceInit[i]);
    }
    expect(await proxyDcarbon.name()).to.equal("DCarbon");
    // Upgrade
    await proxyDcarbon.upgradeTo(dcarbon2.address);
    // console.log("After upgrade");
    for (var i = 0; i < ownerInit.length; i++) {
      expect(
        (await proxyDcarbon.balanceOf(ownerInit[i])).toHexString()
      ).to.equal(balanceInit[i]);
    }
    // expect(await proxyDcarbon.name()).to.equal("DCarbon");
    proxyDcarbon = DCarbonFactory2.attach(proxy.address);
    expect(await proxyDcarbon.hello()).to.equal("hello_dcarbon_2");
  });
});
