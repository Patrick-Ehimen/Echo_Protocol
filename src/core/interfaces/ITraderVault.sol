// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITraderVault
 * @dev Interface for a trader vault that provides methods to get the base token address and the portfolio value.
 */
interface ITraderVault {
    /**
     * @notice Gets the base token address.
     * @return The address of the base token.
     */
    function getBaseToken() external view returns (address);

    /**
     * @notice Gets the portfolio value.
     * @return The value of the portfolio in uint256.
     */
    function getPortfolioValue() external view returns (uint256);
}
