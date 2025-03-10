// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IFeeManager
 * @dev Interface for managing fee calculations in the protocol.
 */
interface IFeeManager {
    /**
     * @notice Calculates the fees for a given vault, token, and amount.
     * @param vault The address of the vault for which fees are being calculated.
     * @param token The address of the token for which fees are being calculated.
     * @param amount The amount of tokens for which fees are being calculated.
     * @return The calculated fee amount.
     */
    function calculateFees(
        address vault,
        address token,
        uint256 amount
    ) external returns (uint256);

    function calculateSwapFee(uint256 amount) external returns (uint256);
}
