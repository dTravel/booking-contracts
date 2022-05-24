import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import hre from 'hardhat'

async function main() {

  const DtravelEIP712 = await ethers.getContractFactory('DtravelEIP712');
  const dtravelEIP712 = await DtravelEIP712.deploy();
  await dtravelEIP712.deployed();

  const dtravelFactory = await ethers.getContractFactory('DtravelFactory', {
    libraries: {
      DtravelEIP712: dtravelEIP712.address
    }
  })
  const factoryContract = await dtravelFactory.deploy('0xe8167D79F5E7bc460Ebdd830bA9cc6Ca43799feD')

  // The address the Contract WILL have once mined
  console.log(factoryContract.address)

  // The transaction that was sent to the network to deploy the Contract
  console.log(factoryContract.deployTransaction.hash)

  await factoryContract.deployed()

  // await hre.run('verify:verify', {
  //   address: factoryContract.address,
  //   constructorArguments: [],
  // })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
