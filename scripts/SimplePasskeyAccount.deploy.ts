import { ethers } from "hardhat";

async function main() {
  const [deployerWallet] = await ethers.getSigners();
  console.log(`SimplePasskeyAccount Factory Deployer : ${deployerWallet.address}`)

  const entryPointAddress = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789'
  
  console.log("Deploying simplePasskeyAccountFactory")
  const simplePasskeyAccountFactoryArtifacts = await ethers.getContractFactory("SimplePasskeyAccountFactory");
  const simplePasskeyAccountFactory = await simplePasskeyAccountFactoryArtifacts.deploy(entryPointAddress,{ gasPrice: 10e10  })
  console.log(`simplePasskeyAccountFactory contract address: ${simplePasskeyAccountFactory.target} \n`)

  const passkeyId = ethers.toUtf8Bytes("passkeyCredentialId")
  const pubKeyX = "58640826831948292943175879036424064544903064261202148179375876287662359819382"
  const pubKeyY = "35488965690999393053537793469671322029993511314321148723800137444087697436355"
  const index = "0"

  const deployerSCWAddress = await simplePasskeyAccountFactory.getCounterfactualAddress(pubKeyX,pubKeyY,index,passkeyId)
  console.log(`SCW address: ${deployerSCWAddress}`)
  
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
