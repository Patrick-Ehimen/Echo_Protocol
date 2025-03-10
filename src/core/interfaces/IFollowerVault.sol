// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFollowerVault {
    function mirrorTrade(
        address tokenIn,
        address tokenOut,
        uint256 traderAmountIn,
        uint256 traderTotalValue,
        uint256 minAmountOut
    ) external returns (uint256 copiedAmount, uint256 fees);
}
