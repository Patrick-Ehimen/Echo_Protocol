// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IVault
 * @dev Interface for a Vault contract
 */
interface IVault {
    /**
     * @notice Initializes the vault with the given owner and base token
     * @param owner The address of the owner of the vault
     * @param baseToken The address of the base token used in the vault
     */
    function initialize(address owner, address baseToken) external;

    /**
     * @notice Returns the address of the base token used in the vault
     * @return The address of the base token
     */
    function getBaseToken() external view returns (address);

    /**
     * @notice Returns the address of the owner of the vault
     * @return The address of the owner
     */
    function getOwner() external view returns (address);
}
