const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");
const { expect } = require("chai");
const { Contract } = require("ethers");
const { parseEther } = require("ethers/lib/utils");
const { ethers, network } = require("hardhat");

const carbonName = "CARBON";
const carbonSymbol = "CB";
const carbonVersion = "1";
const oneDay = 86400;
const iotTypeTest = 65123;

const msgIsNotOwner = "Ownable: caller is not the owner";
const msgDeviceNotActived = "M0023";

const address0 = "0x0000000000000000000000000000000000000000";
const types = {
  Mint: [
    {
      name: "iot",
      type: "address",
    },
    {
      name: "amount",
      type: "uint256",
    },
    {
      name: "nonce",
      type: "uint256",
    },
  ],
};
const foundationAddress = "0xD0b5b174dB586bFC076A7A8E12bee2468aeD0E93";

function getDomain(contractAddress) {
  return {
    name: carbonName,
    version: carbonVersion,
    chainId: "1337",
    verifyingContract: contractAddress,
  };
}

/**
 *
 * @param {Contract} carbonCt
 * @param {SignerWithAddress} signer
 * @param {*} data
 * @returns {Promise<import("ethers").Transaction>}
 */
async function signAndMint(carbonCt, signer, data) {
  const signature = await signer._signTypedData(
    getDomain(carbonCt.address),
    types,
    data
  );

  const { r, s, v } = ethers.utils.splitSignature(signature);

  return await carbonCt.mint(signer.address, data.amount, data.nonce, v, r, s);
}

describe("Carbon", () => {
  let [account1, account2, account3] = [];

  let dProxy;
  let dcarbon;
  let carbon;
  let carbonProxy;

  beforeEach(async () => {
    [account1, account2, account3] = await ethers.getSigners();

    const ProxyFactory = await ethers.getContractFactory("Proxy");
    const CarbonFactory = await ethers.getContractFactory("Carbon");
    const DCarbonFactory = await ethers.getContractFactory("DCarbon");

    dcarbon = await DCarbonFactory.deploy();
    await dcarbon.deployed();

    const dProxyContract = await ProxyFactory.deploy(dcarbon.address);
    dProxy = DCarbonFactory.attach(dProxyContract.address);

    carbon = await CarbonFactory.deploy();
    await carbon.deployed();

    const cProxyContract = await ProxyFactory.deploy(carbon.address);
    carbonProxy = CarbonFactory.attach(cProxyContract.address);

    await carbonProxy.initialize(carbonName, carbonSymbol, dProxy.address);
    await carbonProxy.setLimit(iotTypeTest, ethers.utils.parseEther("120"));

    await dProxy.initialize(
      [carbonProxy.address],
      [ethers.utils.parseEther("100")]
    );
  });

  describe("Initialize", () => {
    it("should ownable by deployer", async () => {
      expect(await carbonProxy.owner()).to.be.equal(account1.address);
    });

    it("should return name and symbol correctly", async () => {
      expect(await carbonProxy.name()).to.be.equal(carbonName);
      expect(await carbonProxy.symbol()).to.be.equal(carbonSymbol);
    });

    it("should revert if Initialize more than one time", async () => {
      await expect(
        carbonProxy.initialize(carbonName, carbonSymbol, dProxy.address)
      ).to.be.revertedWith(`Initializable: contract is already initialized`);
    });
  });

  describe("ERC20Minter", () => {
    let rTest = ethers.utils.formatBytes32String("test");
    let sTest = ethers.utils.formatBytes32String("test");

    describe("Enable Project", () => {
      it("should revert if not owner", async () => {
        await expect(
          carbonProxy
            .connect(account2)
            .enableDevice(account2.address, account3.address, 100)
        ).to.be.revertedWith(msgIsNotOwner);
      });

      it("should revert if device was set owner ", async () => {
        await carbonProxy.enableDevice(
          account2.address,
          account3.address,
          iotTypeTest
        );

        await expect(
          carbonProxy.enableDevice(
            account1.address,
            account3.address,
            iotTypeTest
          )
        ).to.be.revertedWith("M0100");
      });

      // it("should revert if owner address parameter is address 0", async () => {
      //   await expect(carbonProxy.enableDevice(address0, [account3.address])).to
      //     .be.reverted;
      // });

      it("should revert if iot address parameter is not yet set", async () => {
        await expect(
          carbonProxy.enableDevice(account2.address, address0, 123)
        ).to.be.revertedWith("M0020");
      });

      it("should revert if iot type is not set", async () => {
        await expect(
          carbonProxy.enableDevice(account2.address, account3.address, 10)
        ).to.be.revertedWith("M0021");
      });

      it("should enable project correctly", async () => {
        const tx = await carbonProxy.enableDevice(
          account2.address,
          account3.address,
          iotTypeTest
        );

        await expect(tx)
          .to.be.emit(carbonProxy, "EnableDevice")
          .withArgs(account2.address, account3.address);

        //get nonce
        expect(await carbonProxy.getNonce(account3.address)).to.be.equal(0);
      });
    });

    describe("SuspendDevice", () => {
      it("should revert if not owner", async () => {
        await expect(
          carbonProxy.connect(account2).suspendDevice(account1.address)
        ).to.be.revertedWith(msgIsNotOwner);
      });
      it("should emit event correctly", async () => {
        const tx = await carbonProxy.suspendDevice(account1.address);
        await expect(tx)
          .to.be.emit(carbonProxy, "SuspendDevice")
          .withArgs(account1.address);
      });
    });

    describe("SetLimit", () => {
      it("should revert if not owner", async () => {
        await expect(
          carbonProxy.connect(account2).setLimit(iotTypeTest, 123)
        ).to.be.revertedWith(msgIsNotOwner);
      });

      it("should emit event correctly", async () => {
        const tx = await carbonProxy.setLimit(iotTypeTest, parseEther("1"));
        await expect(tx)
          .to.be.emit(carbonProxy, "ChangeLimit")
          .withArgs(iotTypeTest, parseEther("1"));
      });
    });

    describe("setCoefficient", () => {
      it("should revert if not owner", async () => {
        await expect(
          carbonProxy.connect(account2).setCoefficient(rTest, 123)
        ).to.be.revertedWith(msgIsNotOwner);
      });

      it("should emit event correctly", async () => {
        const tx = await carbonProxy.setCoefficient(rTest, 123);
        await expect(tx)
          .to.be.emit(carbonProxy, "ChangeCoefficient")
          .withArgs(rTest, 123);
      });
    });

    describe("mint", () => {
      beforeEach(async () => {
        await carbonProxy.enableDevice(
          account1.address,
          account3.address,
          iotTypeTest
        );
        // await carbonProxy.setLimit(iotTypeTest, ethers.utils.parseEther("10"));
      });

      it("should revert if device is not exist", async () => {
        await expect(
          carbonProxy.mint(
            account1.address,
            ethers.utils.parseEther("1"),
            0,
            0,
            rTest,
            rTest
          )
        ).to.be.revertedWith(msgDeviceNotActived);
      });

      it("should revert if device is not enable", async () => {
        await carbonProxy.suspendDevice(account2.address);
        await expect(
          carbonProxy.mint(
            account2.address,
            ethers.utils.parseEther("1"),
            0,
            0,
            rTest,
            rTest
          )
        ).to.be.revertedWith(msgDeviceNotActived);
      });

      it("should revert if iot is address 0", async () => {
        await expect(
          carbonProxy.mint(
            address0,
            ethers.utils.parseEther("1"),
            0,
            0,
            rTest,
            sTest
          )
        ).to.be.revertedWith(msgDeviceNotActived);
      });

      it("should revert if nonce of device is invalid", async () => {
        await expect(
          carbonProxy.mint(
            account2.address,
            ethers.utils.parseEther("1"),
            3,
            0,
            rTest,
            rTest
          )
        ).to.be.revertedWith(msgDeviceNotActived);
      });

      it("should revert if time between two mint is smaller than one day", async () => {
        await expect(
          carbonProxy.mint(
            account2.address,
            ethers.utils.parseEther("1"),
            1,
            0,
            rTest,
            sTest
          )
        ).to.be.revertedWith(msgDeviceNotActived);
      });

      it("should revert if iot address != signer", async () => {
        const pKey = new ethers.Wallet.createRandom();
        const iotWallet = new ethers.Wallet(pKey, ethers.provider);

        await carbonProxy.enableDevice(
          account1.address,
          iotWallet.address,
          iotTypeTest
        );
        await network.provider.send("evm_increaseTime", [oneDay * 2]);
        await network.provider.send("evm_mine", []);

        const signers = await ethers.getSigners();

        const domain = getDomain(carbonProxy.address);

        const data = {
          iot: iotWallet.address,
          amount: ethers.utils.parseEther("1"),
          nonce: 1,
        };

        const signature = await signers[0]._signTypedData(domain, types, data);
        const { r, s, v } = ethers.utils.splitSignature(signature);

        await expect(
          carbonProxy
            .connect(account2)
            .mint(iotWallet.address, ethers.utils.parseEther("1"), 1, v, r, s)
        ).to.be.revertedWith("M0002");
      });

      it("should revert if not owner of the iot device", async () => {
        const pKey = new ethers.Wallet.createRandom();
        const signer = new ethers.Wallet(pKey, ethers.provider);

        await carbonProxy.enableDevice(
          account1.address,
          signer.address,
          iotTypeTest
        );
        await network.provider.send("evm_increaseTime", [oneDay * 2]);
        await network.provider.send("evm_mine", []);

        const data = {
          iot: signer.address,
          amount: ethers.utils.parseEther("1"),
          nonce: 1,
        };

        await expect(
          signAndMint(carbonProxy.connect(account2), signer, data)
        ).to.be.revertedWith("M0003");
      });

      it("should mint correctly and withdraw correctly", async () => {
        const pKey = new ethers.Wallet.createRandom();
        const iotWal = new ethers.Wallet(pKey, ethers.provider);

        await carbonProxy.enableDevice(
          account2.address,
          iotWal.address,
          iotTypeTest
        );
        await network.provider.send("evm_increaseTime", [oneDay * 2]);
        await network.provider.send("evm_mine", []);

        var totalCarbon = ethers.utils.parseUnits("2.5", 9);
        var carbonFee = totalCarbon.mul(5e7).div(1e9);
        var carbonRemain = totalCarbon.sub(carbonFee);
        var bonusDCarbon = totalCarbon.div(2);

        const data = {
          iot: iotWal.address,
          amount: totalCarbon,
          nonce: 1,
        };

        var cbProxy2 = carbonProxy.connect(account2);
        await signAndMint(cbProxy2, iotWal, data);

        expect(
          await cbProxy2.getNonce(iotWal.address),
          "Nonce should be increase"
        ).to.be.equal(1);
        expect(
          await cbProxy2.balanceOf(account2.address),
          "Carbon balance of owner should increase "
        ).to.be.equal(carbonRemain);
        // expect(await cbProxy2.balanceOf(foundationAddress)).to.be.equal(
        //   carbonFee
        // );

        expect(
          await cbProxy2.getDCarbon(account2.address),
          "DCarbon balance of owner should be increase"
        ).to.be.equal(bonusDCarbon);

        //drawDcarbon correcttly
        const txWithdraw = await cbProxy2.withdrawDCarbon(bonusDCarbon);

        await expect(txWithdraw)
          .to.be.emit(dProxy, "Transfer")
          .withArgs(cbProxy2.address, account2.address, bonusDCarbon);

        expect(await dProxy.balanceOf(account2.address)).to.be.equal(
          bonusDCarbon
        );
      });
    });

    describe("withdrawDCarbon", () => {
      it("should revert if amount not enought", async () => {
        await expect(carbonProxy.withdrawDCarbon(ethers.utils.parseEther("2")))
          .to.be.reverted;
      });
    });
  });
});
