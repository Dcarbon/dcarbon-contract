const { ethers, network } = require("hardhat");

describe("Proxy", () => {
  let [account1, account2, account3] = [];

  let dProxy;
  let dcarbon;

  beforeEach(async () => {
    [account1, account2, account3] = await ethers.getSigners();

    const ProxyFactory = await ethers.getContractFactory("Proxy");
    const DCarbonFactory = await ethers.getContractFactory("DCarbon");

    dcarbon = await DCarbonFactory.deploy();
    await dcarbon.deployed();

    const dProxyContract = await ProxyFactory.deploy(dcarbon.address);
    dProxy = DCarbonFactory.attach(dProxyContract.address);

    await carbonProxy.setLimit(iotTypeTest, ethers.utils.parseEther("120"));

    await dProxy.initialize(
      [carbonProxy.address],
      [ethers.utils.parseEther("100")]
    );
  });

  describe("", () => {});
});
