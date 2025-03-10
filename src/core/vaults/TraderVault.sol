// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IProxyController} from "../interfaces/IProxyController.sol";

contract TraderVault is Initializable, OwnableUpgradeable, ReentrancyGuard {
    // Address of the base token used in the vault
    address public baseToken;

    // Address of the proxy controller contract
    address public proxyController;

    // Address of the fee manager contract
    address public feeManager;

    // Total amount of deposits made into the vault
    uint256 public totalDeposits;

    // Total amount of withdrawals made from the vault
    uint256 public totalWithdrawals;

    // The highest value the portfolio has reached
    uint256 public highWaterMark;

    /**
     * @dev Emitted when a user deposits funds into the vault.
     * @param user The address of the user making the deposit.
     * @param amount The amount of funds deposited.
     */
    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws funds from the vault.
     * @param user The address of the user making the withdrawal.
     * @param amount The amount of funds withdrawn.
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a trade is executed by a trader.
     * @param trader The address of the trader executing the trade.
     * @param tokenIn The address of the token being traded in.
     * @param tokenOut The address of the token being traded out.
     * @param amountIn The amount of the token being traded in.
     * @param amountOut The amount of the token being traded out.
     */
    event TradeExecuted(
        address indexed trader,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev Modifier to make a function callable only by the proxy controller.
     * Reverts if the caller is not the proxy controller.
     */
    modifier onlyProxy() {
        require(msg.sender == proxyController, "Caller is not proxy");
        _;
    }

    /**
     * @notice Initializes the TraderVault contract with the given owner and base token.
     * @dev This function is an initializer and can only be called once.
     * @param _owner The address of the owner of the contract.
     * @param _baseToken The address of the base token used in the vault.
     */
    function initialize(
        address _owner,
        address _baseToken
    ) external initializer {
        __Ownable_init(_owner);
        transferOwnership(_owner);
        baseToken = _baseToken;
    }

    /**
     * @notice Deposits a specified amount of base tokens into the vault.
     * @dev Transfers the specified amount of base tokens from the sender to the vault.
     *      Updates the total deposits and the high water mark.
     * @param amount The amount of base tokens to deposit. Must be greater than 0.
     * @custom:modifier nonReentrant Ensures that the function cannot be re-entered.
     * @custom:event Deposit Emitted when a deposit is made, with the sender's address and the amount deposited.
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");

        IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        totalDeposits += amount;

        _updateHighWaterMark();
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraws a specified amount of the base token from the vault.
     * @dev This function can only be called by the owner and is protected against reentrancy.
     * @param amount The amount of the base token to withdraw. Must be less than or equal to the available balance.
     * @custom:modifier onlyOwner Ensures that the function can only be called by the owner.
     * @custom:modifier nonReentrant Ensures that the function cannot be re-entered.
     * @custom:event Withdraw Emitted when a withdrawal is made, with the owner's address and the amount withdrawn.
     */
    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        require(amount <= availableToWithdraw(), "Exceeds available balance");

        totalWithdrawals += amount;
        IERC20(baseToken).transfer(owner(), amount);

        emit Withdraw(owner(), amount);
    }

    /**
     * @notice Executes a token swap from `tokenIn` to `tokenOut`.
     * @dev This function can only be called by the contract owner and is non-reentrant.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of `tokenIn` to swap.
     * @param minAmountOut The minimum amount of `tokenOut` to receive from the swap.
     * @return receivedAmount The amount of `tokenOut` received from the swap.
     * @custom:modifier onlyOwner Ensures that the function can only be called by the owner.
     * @custom:modifier nonReentrant Ensures that the function cannot be re-entered.
     * @custom:event TradeExecuted Emitted when a trade is executed, with the owner's address, the input and output tokens, and the amounts.
     */
    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external onlyOwner nonReentrant returns (uint256 receivedAmount) {
        // Ensures that the vault has sufficient balance of the input token.
        require(amountIn <= _availableBalance(tokenIn), "Insufficient balance");

        IERC20(tokenIn).approve(proxyController, amountIn);
        receivedAmount = IProxyController(proxyController).executeSwap(
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut
        );

        _updateHighWaterMark();
        emit TradeExecuted(
            owner(),
            tokenIn,
            tokenOut,
            amountIn,
            receivedAmount
        );
    }

    /**
     * @notice Returns the total value of the portfolio.
     * @dev This function calculates the total value by summing the balance of the base token held by the contract and the current value of other assets.
     * @return The total value of the portfolio in uint256.
     */
    function getPortfolioValue() public view returns (uint256) {
        return
            IERC20(baseToken).balanceOf(address(this)) +
            _calculateCurrentValue();
    }

    /**
     * @notice Calculates the amount available to withdraw from the vault.
     * @dev This function compares the current portfolio value with the high water mark.
     * @return The amount available to withdraw. If the current value is less than or equal to the high water mark, returns 0.
     */
    function availableToWithdraw() public view returns (uint256) {
        uint256 currentValue = getPortfolioValue();
        return currentValue > highWaterMark ? currentValue - highWaterMark : 0;
    }

    /**
     * @notice Sets the address of the proxy controller.
     * @dev This function can only be called by the owner of the contract.
     * @param _proxy The address of the new proxy controller.
     */
    function setProxyController(address _proxy) external onlyOwner {
        proxyController = _proxy;
    }

    /**
     * @notice Sets the address of the fee manager.
     * @dev This function can only be called by the owner of the contract.
     * @param _feeManager The address of the new fee manager.
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    /**
     * @notice Returns the available balance of a given token in the vault.
     * @dev If the token is the base token, the available balance is calculated by subtracting
     *      the net deposits (totalDeposits - totalWithdrawals) from the token balance of the vault.
     * @param token The address of the token to check the balance for.
     * @return The available balance of the specified token in the vault.
     */
    function _availableBalance(address token) internal view returns (uint256) {
        return
            token == baseToken
                ? IERC20(token).balanceOf(address(this)) -
                    (totalDeposits - totalWithdrawals)
                : IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Updates the high water mark to the current portfolio value if the current value is higher.
     * The high water mark is used to track the highest value the portfolio has reached.
     * This function is internal and can only be called within the contract or derived contracts.
     */
    function _updateHighWaterMark() internal {
        uint256 currentValue = getPortfolioValue();
        if (currentValue > highWaterMark) {
            highWaterMark = currentValue;
        }
    }

    function _calculateCurrentValue() internal pure returns (uint256) {
        // Implementation would use oracle pricing
        return 0; // Placeholder
    }
}
