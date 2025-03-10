// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract ProxyController is Ownable, ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    address public feeManager;

    mapping(address => bool) public authorizedVaults;

    event SwapExecuted(
        address indexed vault,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    modifier onlyAuthorized() {
        require(authorizedVaults[msg.sender], "Unauthorized caller");
        _;
    }

    constructor(address _swapRouter) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external onlyAuthorized nonReentrant returns (uint256 amountOut) {
        // Transfer tokens from vault to proxy
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve Uniswap router
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp + 15 minutes,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        // Deduct fees from output amount
        uint256 fee = IFeeManager(feeManager).calculateSwapFee(amountOut);
        if (fee > 0) {
            IERC20(tokenOut).transfer(feeManager, fee);
            amountOut -= fee;
        }

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function addAuthorizedVault(address vault) external onlyOwner {
        authorizedVaults[vault] = true;
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }
}
