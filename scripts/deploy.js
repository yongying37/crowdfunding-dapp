const hre = require("hardhat");

async function main() {
  const CrowdFund = await hre.ethers.getContractFactory("CrowdFund");
  const contract = await CrowdFund.deploy();

  await contract.waitForDeployment();

  console.log("✅ Contract deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});