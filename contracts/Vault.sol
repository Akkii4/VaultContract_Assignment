// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

/**
 * @title Vault
 * @dev A smart contract for depositing, withdrawing ETH and ERC20 tokens, and wrapping/unwrapping ETH to/from WETH.
 */
contract Vault {
    using SafeERC20 for IERC20;

    IWETH public immutable weth;
    mapping(address => uint256) public userETHBalance;
    mapping(address => mapping(address => uint256)) public userTokenBalance;

    event EthDeposited(address indexed user, uint256 amount);
    event EthWithdrawn(address indexed user, uint256 amount);
    event TokenDeposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event TokenWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event WrappedETH(address indexed user, uint256 amount);
    event UnwrappedETH(address indexed user, uint256 amount);

    error ZeroETH();
    error InsufficientBalance();
    error ZeroToken();
    error InvalidTokenAddress();

    /**
     * @dev Constructor initializes the contract with the WETH token address.
     * @param _weth Address of the WETH token contract.
     * @notice weth address will be immutable and can't be changed further
     */
    constructor(address _weth) {
        weth = IWETH(_weth);
    }

    /**
     * @dev Fallback function to handle ETH deposits directly.
     */
    receive() external payable {}

    /**
     * @dev Function to deposit ETH into the vault.
     */
    function depositETH() external payable {
        if (msg.value == 0) revert ZeroETH();
        userETHBalance[msg.sender] += msg.value;
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Function to withdraw ETH from the vault.
     * @param amount Amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external {
        if (amount == 0) revert ZeroETH();
        if (userETHBalance[msg.sender] < amount) revert InsufficientBalance();
        userETHBalance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Function to deposit ERC20 tokens into the vault.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to deposit.
     */
    function depositToken(address token, uint256 amount) external {
        if (token == address(0)) revert InvalidTokenAddress();
        if (amount == 0) revert ZeroToken();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        userTokenBalance[msg.sender][token] += amount;
        emit TokenDeposited(msg.sender, token, amount);
    }

    /**
     * @dev Function to withdraw ERC20 tokens from the vault.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawToken(address token, uint256 amount) external {
        if (token == address(0)) revert InvalidTokenAddress();
        if (amount == 0) revert ZeroToken();
        if (userTokenBalance[msg.sender][token] < amount)
            revert InsufficientBalance();
        userTokenBalance[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, token, amount);
    }

    /**
     * @dev Function to wrap ETH into WETH.
     * @param amount Amount of ETH to wrap.
     */
    function wrapETH(uint256 amount) external {
        if (amount == 0) revert ZeroETH();
        if (userETHBalance[msg.sender] < amount) revert InsufficientBalance();
        userETHBalance[msg.sender] -= amount;
        userTokenBalance[msg.sender][address(weth)] += amount;
        weth.deposit{value: amount}();
        emit WrappedETH(msg.sender, amount);
    }

    /**
     * @dev Function to unwrap WETH into ETH.
     * @param amount Amount of WETH to unwrap.
     */
    function unwrapWETH(uint256 amount) external {
        if (amount == 0) revert ZeroETH();
        if (userTokenBalance[msg.sender][address(weth)] < amount)
            revert InsufficientBalance();
        userTokenBalance[msg.sender][address(weth)] -= amount;
        userETHBalance[msg.sender] += amount;
        weth.withdraw(amount);
        emit UnwrappedETH(msg.sender, amount);
    }

    /**
     * @dev Function to get the WETH balance of a user.
     * @param user Address of the user.
     * @return balance The WETH balance of the user.
     */
    function userWETHBalance(
        address user
    ) public view returns (uint256 balance) {
        balance = userTokenBalance[user][address(weth)];
    }
}
