// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
// const ethers = hre.ethers;

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Owner address is:", deployer.address);

  const EmployeeId = await ethers.getContractFactory("EmployeeId");
  const employeeId = await EmployeeId.deploy(
  //   {
  //   // gasLimit: 400000,  // ガスリミットを増やす
  //   // maxFeePerGas: ethers.parseUnits('2', 'gwei'),  // 必要に応じてガスプライスを調整
  //   // maxPriorityFeePerGas: ethers.parseUnits('1', 'gwei')
  // }
  );
  await employeeId.waitForDeployment();

  const BusinessCard = await ethers.getContractFactory("BusinessCard");
  const businessCard = await BusinessCard.deploy(employeeId.target
  //   , {
  //   gasLimit: 400000,  // ガスリミットを増やす
  //   maxFeePerGas: ethers.parseUnits('2', 'gwei'),  // 必要に応じてガスプライスを調整
  //   maxPriorityFeePerGas: ethers.parseUnits('1', 'gwei')
  // }
  );
  await businessCard.waitForDeployment(); 

  console.log("EmployeeId contract deployed to:", employeeId.target);
  console.log("BusinessCard contract deployed to:", businessCard.target);

  // const ownerAddress = await employeeId.owner();
  // console.log("The owner of the contract is:", ownerAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
