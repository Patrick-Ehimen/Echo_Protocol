// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IProxyController} from "../interfaces/IProxyController.sol";
import {ITraderVault} from "../interfaces/ITraderVault.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";

contract FollowerVault is Initializable, OwnableUpgradeable, ReentrancyGuard {
    address public baseToken;
    address public traderVault;
    address public proxyController;
    address public feeManager;

    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public highWaterMark;

    /**
     * @dev Mapping to store the token balances of each address.
     */
    mapping(address => uint256) public tokenBalances;

    /**
     * @dev Emitted when a deposit is made.
     * @param user The address of the user making the deposit.
     * @param amount The amount of tokens deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a withdrawal is made.
     * @param user The address of the user making the withdrawal.
     * @param token The address of the token being withdrawn.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawal(address indexed user, address token, uint256 amount);

    /**
     * @dev Emitted when a trade is mirrored.
     * @param trader The address of the trader whose trade is being mirrored.
     * @param tokenIn The address of the token being traded in.
     * @param tokenOut The address of the token being traded out.
     * @param amountIn The amount of tokens being traded in.
     * @param amountOut The amount of tokens being traded out.
     */
    event TradeMirrored(
        address indexed trader,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev Modifier to make a function callable only by the mirror contract.
     * Reverts if the caller is not the mirror contract.
     *
     * Requirements:
     *
     * - The caller must be the proxyController.
     */
    modifier onlyMirrorContract() {
        require(msg.sender == proxyController, "Caller is not mirror contract");
        _;
    }

    /**
     * @notice Initializes the FollowerVault contract with the given owner and trader vault addresses.
     * @dev This function is an initializer and can only be called once.
     * @param _owner The address of the owner of the FollowerVault.
     * @param _traderVault The address of the trader vault associated with this FollowerVault.
     */
    function initialize(
        address _owner,
        address _traderVault
    ) external initializer {
        __Ownable_init();
        _transferOwnership(_owner);
        traderVault = _traderVault;
        baseToken = ITraderVault(_traderVault).getBaseToken();
    }

    /**
     * @notice Deposits a specified amount of base tokens into the vault.
     * @dev Transfers the specified amount of base tokens from the sender to the vault,
     *      updates the token balance and total deposits, and updates the high water mark.
     * @param amount The amount of base tokens to deposit. Must be greater than 0.
     * @custom:modifier nonReentrant Ensures that the function cannot be re-entered.
     * @custom:event Deposit Emitted when a deposit is made, with the sender's address and the amount deposited.
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");

        IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        tokenBalances[baseToken] += amount;
        totalDeposits += amount;

        _updateHighWaterMark();
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraws a specified amount of a given token from the vault.
     * @dev This function can only be called by the owner and is protected against reentrancy.
     * @param amount The amount of the token to withdraw.
     * @param token The address of the token to withdraw.
     * @custom:modifier onlyOwner Ensures that the function can only be called by the owner.
     * @custom:modifier nonReentrant Ensures that the function cannot be re-entered.
     */
    function withdraw(
        uint256 amount,
        address token
    ) external nonReentrant onlyOwner {
        // The amount to withdraw must not exceed the available balance of the token.
        require(
            amount <= _availableToWithdraw(token),
            "Exceeds available balance"
        );

        if (token == baseToken) {
            totalWithdrawals += amount;
        }

        tokenBalances[token] -= amount;
        IERC20(token).transfer(owner(), amount);

        emit Withdrawal(owner(), token, amount);
    }

    /**
     * @notice Mirrors a trade from the trader's vault to the follower's vault.
     * @dev This function can only be called by the mirror contract and is non-reentrant.
     * @param tokenIn The address of the token being swapped from.
     * @param tokenOut The address of the token being swapped to.
     * @param traderAmountIn The amount of tokenIn the trader is swapping.
     * @param traderTotalValue The total value of the trader's vault.
     * @param minAmountOut The minimum amount of tokenOut expected from the swap.
     * @return receivedAmount The amount of tokenOut received from the swap.
     *
     * Requirements:
     * - `tokenIn` must be the base token.
     * - `scaledAmountIn` must be greater than 0 and less than or equal to the follower's allocated balance.
     * - The function will revert if the allocation is insufficient or if an overdraft is prevented.
     */
    function mirrorTrade(
        address tokenIn,
        address tokenOut,
        uint256 traderAmountIn,
        uint256 traderTotalValue,
        uint256 minAmountOut
    )
        external
        onlyMirrorContract
        nonReentrant
        returns (uint256 receivedAmount)
    {
        require(tokenIn == baseToken, "Only base token swaps supported");

        uint256 allocated = tokenBalances[baseToken];
        uint256 scaledAmountIn = (allocated * traderAmountIn) /
            traderTotalValue;

        require(scaledAmountIn > 0, "Insufficient allocation");
        require(
            scaledAmountIn <= tokenBalances[baseToken],
            "Overdraft prevented"
        );

        IERC20(baseToken).approve(proxyController, scaledAmountIn);
        receivedAmount = IProxyController(proxyController).executeSwap(
            tokenIn,
            tokenOut,
            scaledAmountIn,
            minAmountOut
        );

        // Update balances
        tokenBalances[baseToken] -= scaledAmountIn;
        tokenBalances[tokenOut] += receivedAmount;

        // Deduct fees from profit
        uint256 fee = IFeeManager(feeManager).calculateFees(
            address(this),
            tokenOut,
            receivedAmount
        );
        if (fee > 0) {
            tokenBalances[tokenOut] -= fee;
            IERC20(tokenOut).transfer(feeManager, fee);
        }

        _updateHighWaterMark();
        emit TradeMirrored(
            traderVault,
            tokenIn,
            tokenOut,
            scaledAmountIn,
            receivedAmount
        );
    }

    function getCurrentValue() public view returns (uint256) {
        uint256 total = tokenBalances[baseToken];
        // Add logic to calculate value of other tokens using oracle
        return total;
    }

    function setProxyController(address _proxy) external onlyOwner {
        proxyController = _proxy;
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    function _availableToWithdraw(
        address token
    ) internal view returns (uint256) {
        uint256 currentValue = getCurrentValue();
        uint256 profit = currentValue > highWaterMark
            ? currentValue - highWaterMark
            : 0;
        uint256 withdrawable = token == baseToken
            ? tokenBalances[token] - (totalDeposits - totalWithdrawals) + profit
            : tokenBalances[token];

        return withdrawable;
    }

    function _updateHighWaterMark() internal {
        uint256 currentValue = getCurrentValue();
        if (currentValue > highWaterMark) {
            highWaterMark = currentValue;
        }
    }
}
