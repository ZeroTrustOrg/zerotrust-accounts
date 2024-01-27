// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./SimplePasskeyAccount.sol";

/**
 * A sample factory contract for SimplePasskeyAccountFactory
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract SimplePasskeyAccountFactory {
    SimplePasskeyAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new SimplePasskeyAccount(_entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        uint256 pubKeyX,
        uint256 pubKeyY,
        uint salt,
        bytes calldata credentialId
    ) public returns (SimplePasskeyAccount ret) {
        address addr = getCounterfactualAddress(
            pubKeyX,
            pubKeyY,
            salt,
            credentialId
        );
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return SimplePasskeyAccount(payable(addr));
        }
        ret = SimplePasskeyAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(
                        SimplePasskeyAccount.initialize,
                        (pubKeyX, pubKeyY, credentialId)
                    )
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getCounterfactualAddress(
        uint256 pubKeyX,
        uint256 pubKeyY,
        uint salt,
        bytes calldata credentialId
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(accountImplementation),
                            abi.encodeCall(
                                SimplePasskeyAccount.initialize,
                                (pubKeyX, pubKeyY, credentialId)
                            )
                        )
                    )
                )
            );
    }
}
