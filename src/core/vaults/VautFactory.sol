// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {IVault} from "../interfaces/IVault.sol";

/// @title VaultFactory
/// @notice This contract is responsible for creating trader and follower vaults.
/// @dev Uses Create2 for deterministic address generation.
contract VaultFactory is Ownable {
    /// @notice Emitted when a trader vault is created.
    /// @param owner The address of the owner of the vault.
    /// @param vault The address of the created vault.
    /// @param baseToken The address of the base token used in the vault.
    event TraderVaultCreated(
        address indexed owner,
        address vault,
        address baseToken
    );

    /// @notice Emitted when a follower vault is created.
    /// @param follower The address of the follower.
    /// @param vault The address of the created vault.
    /// @param trader The address of the trader being followed.
    event FollowerVaultCreated(
        address indexed follower,
        address vault,
        address indexed trader
    );

    /// @notice The implementation address for trader vaults
    address public traderVaultImplementation;
    /// @notice The implementation address for follower vaults
    address public followerVaultImplementation;

    /// @notice Mapping from an address to an array of their trader vaults
    mapping(address => address[]) public traderVaults;
    /// @notice Mapping from an address to an array of their follower vaults
    mapping(address => address[]) public followerVaults;

    /**
     * @notice Constructor for the VaultFactory contract.
     * @param _traderVaultImpl The address of the trader vault implementation contract.
     * @param _followerVaultImpl The address of the follower vault implementation contract.
     * @param initialOwner The address of the Contract's Owner
     */
    constructor(
        address _traderVaultImpl,
        address _followerVaultImpl,
        address initialOwner
    ) {
        traderVaultImplementation = _traderVaultImpl;
        followerVaultImplementation = _followerVaultImpl;
        _transferOwnership(initialOwner);
    }

    /**
     * @notice Creates a new trader vault for the specified base token.
     * @dev Uses the Create2 opcode to deploy the vault with a deterministic address.
     * @param baseToken The address of the base token for the trader vault.
     * @return The address of the newly created trader vault.
     *
     * Emits a {TraderVaultCreated} event.
     */
    function createTraderVault(address baseToken) external returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, baseToken, block.timestamp)
        );
        address vault = Create2.deploy(
            0,
            salt,
            _getTraderVaultCreationCode(baseToken)
        );

        traderVaults[msg.sender].push(vault);
        emit TraderVaultCreated(msg.sender, vault, baseToken);
        return vault;
    }

    /**
     * @notice Creates a new follower vault for the specified trader.
     * @dev Uses the Create2 opcode to deploy the follower vault with a unique salt.
     * @param trader The address of the trader for whom the follower vault is being created.
     * @return The address of the newly created follower vault.
     */
    function createFollowerVault(address trader) external returns (address) {
        // The trader must have at least one existing vault.
        require(
            traderVaults[trader].length > 0,
            "VaultFactory: Trader has no vaults"
        );

        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, trader, block.timestamp)
        );
        address vault = Create2.deploy(
            0,
            salt,
            _getFollowerVaultCreationCode(trader)
        );

        followerVaults[msg.sender].push(vault);

        // FollowerVaultCreated Emitted when a new follower vault is created.
        emit FollowerVaultCreated(msg.sender, vault, trader);
        return vault;
    }

    /**
     * @notice Retrieves the vault addresses associated with a specific trader.
     * @param trader The address of the trader whose vaults are being queried.
     * @return An array of addresses representing the trader's vaults.
     */
    function getTraderVaults(
        address trader
    ) external view returns (address[] memory) {
        return traderVaults[trader];
    }

    /**
     * @notice Retrieves the vault addresses associated with a specific follower.
     * @param follower The address of the follower whose vaults are being queried.
     * @return An array of addresses representing the follower's vaults.
     */
    function getFollowerVaults(
        address follower
    ) external view returns (address[] memory) {
        return followerVaults[follower];
    }

    /**
     * @notice Sets the implementation addresses for trader and follower vaults.
     * @dev This function can only be called by the owner of the contract.
     * @param _traderImpl The address of the trader vault implementation.
     * @param _followerImpl The address of the follower vault implementation.
     */
    function setVaultImplementation(
        address _traderImpl,
        address _followerImpl
    ) external onlyOwner {
        traderVaultImplementation = _traderImpl;
        followerVaultImplementation = _followerImpl;
    }

    /**
     * @dev Generates the creation code for a new trader vault.
     * @param baseToken The address of the base token to be used in the vault.
     * @return creationCode The bytecode for creating a new trader vault.
     */
    function _getTraderVaultCreationCode(
        address baseToken
    ) private view returns (bytes memory) {
        bytes memory creationCode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                traderVaultImplementation,
                abi.encodeWithSelector(
                    IVault.initialize.selector,
                    msg.sender,
                    baseToken
                )
            )
        );
        return creationCode;
    }

    /**
     * @dev Generates the creation code for a follower vault.
     * @param trader The address of the trader for whom the follower vault is being created.
     * @return creationCode The bytecode for creating the follower vault.
     *
     * This function constructs the creation code for a new follower vault using the ERC1967Proxy pattern.
     * It encodes the initialization parameters for the follower vault, including the caller's address and the trader's address.
     */
    function _getFollowerVaultCreationCode(
        address trader
    ) private view returns (bytes memory) {
        bytes memory creationCode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                followerVaultImplementation,
                abi.encodeWithSelector(
                    IVault.initialize.selector,
                    msg.sender,
                    trader
                )
            )
        );
        return creationCode;
    }
}
