const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vault", function () {
  let Vault, vault, WETH, weth, token, owner, addr1, addr2;

  beforeEach(async function () {
    WETH = await ethers.getContractFactory("WETH");
    weth = await WETH.deploy();
    await weth.deployed();

    Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy(weth.address);
    await vault.deployed();

    MockToken = await ethers.getContractFactory("MockToken");
    token = await MockToken.deploy();
    await token.deployed();

    [owner, addr1, addr2, _] = await ethers.getSigners();
  });

  it("Should allow deposits and withdrawals of ETH", async function () {
    await vault
      .connect(addr1)
      .depositETH({ value: ethers.utils.parseEther("1") });
    expect(await vault.userETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("1")
    );

    await vault.connect(addr1).withdrawETH(ethers.utils.parseEther("0.5"));
    expect(await vault.userETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("0.5")
    );
  });

  it("Should allow deposits and withdrawals of ERC20 tokens", async function () {
    await token
      .connect(addr1)
      .mint(addr1.address, ethers.utils.parseEther("1"));
    await token
      .connect(addr1)
      .approve(vault.address, ethers.utils.parseEther("1"));
    await vault
      .connect(addr1)
      .depositToken(token.address, ethers.utils.parseEther("1"));
    expect(await vault.userTokenBalance(addr1.address, token.address)).to.equal(
      ethers.utils.parseEther("1")
    );

    await vault
      .connect(addr1)
      .withdrawToken(token.address, ethers.utils.parseEther("0.5"));
    expect(await vault.userTokenBalance(addr1.address, token.address)).to.equal(
      ethers.utils.parseEther("0.5")
    );
  });

  it("Should wrap and unwrap ETH to and from WETH respectively", async function () {
    await vault
      .connect(addr1)
      .depositETH({ value: ethers.utils.parseEther("1") });
    expect(await vault.userETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("1")
    );

    await vault.connect(addr1).wrapETH(ethers.utils.parseEther("1"));
    expect(await vault.userWETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("1")
    );
    expect(await vault.userETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("0")
    );

    await vault.connect(addr1).unwrapWETH(ethers.utils.parseEther("1"));
    expect(await vault.userWETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("0")
    );
    expect(await vault.userETHBalance(addr1.address)).to.equal(
      ethers.utils.parseEther("1")
    );
  });
});
