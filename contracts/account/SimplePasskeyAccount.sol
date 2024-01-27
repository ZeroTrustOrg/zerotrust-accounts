// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "./callback/TokenCallbackHandler.sol";
import "../webAuthnLibs/WebAuthn.sol";

/**
 * minimal account.
 *  this is sample minimal account.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract SimplePasskeyAccount is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable
{
    struct Passkey {
        uint256 pubKeyX;
        uint256 pubKeyY;
        bytes credentialId;
    }

    struct PasskeySigData {
        uint256 challengeLocation;
        uint256 responseTypeLocation;
        uint256 r;
        uint256 s;
        bool requireUserVerification;
        bytes authenticatorData;
        string clientDataJSON;
    }
    Passkey public signer;
    address public owner;

    IEntryPoint private immutable _entryPoint;

    event SimplePasskeyAccountInitialized(
        IEntryPoint indexed entryPoint,
        Passkey indexed signer
    );

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        // through the account itself (which gets redirected through execute())
        require(msg.sender == address(this), "only owner");
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     */
    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external {
        _requireFromEntryPoint();
        require(
            dest.length == func.length &&
                (value.length == 0 || value.length == func.length),
            "wrong array lengths"
        );
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimplePasskeyAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(
        uint256 pubKeyX,
        uint256 pubKeyY,
        bytes calldata credentialId
    ) public virtual initializer {
        _initialize(pubKeyX, pubKeyY, credentialId);
    }

    function _initialize(
        uint256 pubKeyX,
        uint256 pubKeyY,
        bytes calldata credentialId
    ) internal virtual {
        signer = Passkey(pubKeyX, pubKeyY, credentialId);
        emit SimplePasskeyAccountInitialized(_entryPoint, signer);
    }

    // no-op function with structs as arguments to expose it in generated ABI
    // for client-side usage
    function passkeySignatureStruct(PasskeySigData memory sig) public {}

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        // decode the signature field to get data regarding passkey signature
        PasskeySigData memory passkeyData = abi.decode(
            userOp.signature,
            (PasskeySigData)
        );
        bool result = WebAuthn.verifySignature(
            bytes.concat(userOpHash), // message which is signed over
            passkeyData.authenticatorData,
            passkeyData.requireUserVerification,
            passkeyData.clientDataJSON,
            passkeyData.challengeLocation,
            passkeyData.responseTypeLocation,
            passkeyData.r,
            passkeyData.s,
            signer.pubKeyX,
            signer.pubKeyY
        );
        if (result) {
            return 0;
        }
        return SIG_VALIDATION_FAILED;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyOwner();
    }
}
