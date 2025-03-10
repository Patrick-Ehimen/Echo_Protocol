// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IProxyController
 * @dev Interface for a proxy controller that executes token swaps.
 */
interface IProxyController {
    /**
     * @notice Executes a token swap from `tokenIn` to `tokenOut`.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of the input token to swap.
     * @param minAmountOut The minimum amount of the output token to receive.
     * @return The amount of the output token received.
     */
    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256);
}
