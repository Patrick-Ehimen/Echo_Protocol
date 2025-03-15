// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title IFollowerVault Interface
/// @notice Interface for the Follower Vault to mirror trades
interface IFollowerVault {
    /// @notice Mirrors a trade from a trader
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param traderAmountIn The amount of input tokens the trader is trading
    /// @param traderTotalValue The total value of the trader's portfolio
    /// @param minAmountOut The minimum amount of output tokens expected
    /// @return copiedAmount The amount of tokens copied in the trade
    /// @return fees The fees incurred during the trade
    function mirrorTrade(
        address tokenIn,
        address tokenOut,
        uint256 traderAmountIn,
        uint256 traderTotalValue,
        uint256 minAmountOut
    ) external returns (uint256 copiedAmount, uint256 fees);
}
