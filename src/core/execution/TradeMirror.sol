// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IFollowerVault} from "../interfaces/IFollowerVault.sol";
import {ITraderVault} from "../interfaces/ITraderVault.sol";

contract TradeMirror is Ownable, ReentrancyGuard {
    address public vaultFactory;
    address public feeManager;
    address public proxyController;

    // TraderVault => FollowerVault[]
    mapping(address => address[]) public followersByTrader;

    event TradeCopied(
        address indexed traderVault,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 totalCopiedAmount,
        uint256 totalFees
    );

    constructor(
        address _vaultFactory,
        address _feeManager,
        address initialOwner
    ) Ownable(initialOwner) ReentrancyGuard() {
        vaultFactory = _vaultFactory;
        feeManager = _feeManager;
    }

    function registerFollowerVault(
        address traderVault,
        address followerVault
    ) external {
        require(msg.sender == vaultFactory, "Only VaultFactory");
        followersByTrader[traderVault].push(followerVault);
    }

    function mirrorTrade(
        address traderVault,
        address tokenIn,
        address tokenOut,
        uint256 traderAmountIn,
        uint256 minAmountOut
    ) external nonReentrant onlyOwner {
        require(traderAmountIn > 0, "Invalid trade amount");

        uint256 traderTotalValue = ITraderVault(traderVault)
            .getPortfolioValue();
        require(traderTotalValue > 0, "Trader has no funds");

        address[] storage followers = followersByTrader[traderVault];
        uint256 totalCopied;
        uint256 totalFees;

        for (uint256 i = 0; i < followers.length; i++) {
            address follower = followers[i];

            (uint256 copied, uint256 fees) = IFollowerVault(follower)
                .mirrorTrade(
                    tokenIn,
                    tokenOut,
                    traderAmountIn,
                    traderTotalValue,
                    minAmountOut
                );

            totalCopied += copied;
            totalFees += fees;
        }

        emit TradeCopied(
            traderVault,
            tokenIn,
            tokenOut,
            totalCopied,
            totalFees
        );
    }

    function setProxyController(address _proxy) external onlyOwner {
        proxyController = _proxy;
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    function getFollowersCount(
        address traderVault
    ) external view returns (uint256) {
        return followersByTrader[traderVault].length;
    }
}
