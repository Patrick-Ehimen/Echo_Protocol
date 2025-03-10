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

    /**
     * @notice Checks if the vault is active.
     * @return bool indicating whether the vault is active.
     */
    function isActive() external view returns (bool);

    /**
     * @notice Gets the amount allocated to a specific trader.
     * @param trader The address of the trader.
     * @return uint256 The amount allocated to the trader.
     */
    function getAllocatedToTrader(
        address trader
    ) external view returns (uint256);

    /**
     * @notice Executes a mirror trade from one token to another.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to trade.
     * @param minAmountOut The minimum amount of output tokens expected.
     * @return uint256 The amount of output tokens received.
     */
    function mirrorTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256);
}
