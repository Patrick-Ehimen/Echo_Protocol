// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // Import Address library

import {IVault} from "../interfaces/IVault.sol";

contract FeeManager is Ownable, ReentrancyGuard {
    using Address for address; // Use Address library

    uint256 public constant PROTOCOL_FEE_BPS = 300; // 3%
    uint256 public constant TRADER_FEE_BPS = 700;   // 7%
    
    address public treasury;
    
    mapping(address => mapping(address => uint256)) public protocolFees; // token => amount
    mapping(address => mapping(address => uint256)) public traderFees;    // trader => token => amount

    event FeesCollected(
        address indexed trader,
        address indexed token,
        uint256 protocolAmount,
        uint256 traderAmount
    );

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function calculateAndDeductFees(
        address trader,
        address token,
        uint256 amount
    ) external nonReentrant returns (uint256 netAmount) {
        require(msg.sender.isContract(), "Only authorized contracts"); // Use isContract correctly
        
        uint256 protocolFee = amount * PROTOCOL_FEE_BPS / 10_000;
        uint256 traderFee = amount * TRADER_FEE_BPS / 10_000;
        
        protocolFees[token][address(this)] += protocolFee;
        traderFees[trader][token] += traderFee;
        
        netAmount = amount - protocolFee - traderFee;
        
        emit FeesCollected(trader, token, protocolFee, traderFee);
    }

    function calculatePerformanceFee(
        address vault,
        uint256 profit
    ) public view returns (uint256 fee) {
        require(IVault(vault).highWaterMark() > 0, "No high watermark");
        return profit * TRADER_FEE_BPS / 10_000;
    }

    function withdrawProtocolFees(address token) external onlyOwner {
        uint256 amount = protocolFees[token][address(this)];
        require(amount > 0, "No fees available");
        
        protocolFees[token][address(this)] = 0;
        IERC20(token).transfer(treasury, amount);
    }

    function withdrawTraderFees(address token) external {
        uint256 amount = traderFees[msg.sender][token];
        require(amount > 0, "No fees available");
        
        traderFees[msg.sender][token] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
