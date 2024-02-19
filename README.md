# zerotrust-accounts

**Note:** These contracts have not been audited and should not be used in production environments without thorough testing and security audits.

## Acknowledgements

The smart contract code for validating passkey signatures onchain is used from the [P256Verifier](https://github.com/daimo-eth/p256-verifier/tree/master). 
The relevant smart contracts are in [webAuthnLibs](https://github.com/ZeroTrustOrg/zerotrust-accounts/tree/master/contracts/webAuthnLibs) folder.



## Smart Contracts
This Hardhat project contains smart contract files for `SimplePasskeyAccount` and `SimplePasskeyAccountFactory`.

### [SimplePasskeyAccount.sol](https://github.com/ZeroTrustOrg/zerotrust-accounts/blob/master/contracts/account/SimplePasskeyAccount.sol)
This smart contract defines the `SimplePasskeyAccount`, which uses passkey as a signer to user operations.

### [SimplePasskeyAccountFactory.sol](https://github.com/ZeroTrustOrg/zerotrust-accounts/blob/master/contracts/account/SimplePasskeyAccountFactory.sol)
The `SimplePasskeyAccountFactory` smart contract facilitates the creation of new [SimplePasskeyAccount](https://github.com/ZeroTrustOrg/zerotrust-accounts/blob/master/contracts/account/SimplePasskeyAccount.sol) instances.

## Getting Started

To get started with this project, follow these steps:

1. Clone the repository.
2. Install Hardhat and other dependencies.
3. Create a .env file and set environment values for `SEPOLIA_ALCHEMY_API_KEY` and `PRIVATE_KEY`.
4. Compile the smart contracts.
```shell
npx hardhat compile
```
5.Deploy the contracts to a testnet.
```shell
npx hardhat run scripts/SimplePasskeyAccount.deploy.ts --network ${testnetName}
```

## Usage
You can utilize the `SimplePasskeyAccount` and `SimplePasskeyAccountFactory` contracts to create and manage passkey accounts in your decentralized applications.
