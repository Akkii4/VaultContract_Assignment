const hre = require("hardhat");
const ConstructorParams = require("./constructorParams.json");

async function main() {
  const Vault = await hre.ethers.getContractFactory("Vault");
  const VaultInstance = await Vault.deploy(ConstructorParams.weth);
  await VaultInstance.deployed();
  console.log("Vault deployed at " + VaultInstance.address);
  await VaultInstance.deployTransaction.wait([(confirms = 6)]);

  await hre.run("verify:verify", {
    address: VaultInstance.address,
    constructorArguments: [ConstructorParams.weth],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
