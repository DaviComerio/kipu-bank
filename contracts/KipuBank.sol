// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract KipuBank {
    // ==============================
    // State variables
    // ==============================

    // Max total ETH allowed in the bank (set once at deployment)
    uint256 public immutable BANK_CAP;

    // Max amount per withdrawal (set once at deployment)
    uint256 public immutable WITHDRAWAL_LIMIT;

    // Total ETH currently stored in the bank
    uint256 public totalHeld;

    // Total number of deposits made
    uint256 public totalDepositCount;

    // Total number of withdrawals made
    uint256 public totalWithdrawCount;

    // Mapping: user => balance (in wei)
    mapping(address => uint256) private balances;

    // Mapping: user => number of deposits
    mapping(address => uint256) private userDepositCount;

    // Mapping: user => number of withdrawals
    mapping(address => uint256) private userWithdrawCount;

    // ==============================
    // Events
    // ==============================

    event Deposit(address indexed user, uint256 amount, uint256 totalHeld);
    event Withdrawal(address indexed user, uint256 amount, uint256 remainingBalance);

    // ==============================
    // Custom errors
    // ==============================

    error BankCapReached();
    error ZeroDeposit();
    error ExceedsWithdrawalLimit();
    error InsufficientBalance();
    error ReentrantCall();

    // ==============================
    // Reentrancy protection
    // ==============================

    uint8 private _reentrancyStatus;
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;

    modifier nonReentrant() {
        if (_reentrancyStatus == _ENTERED) revert ReentrantCall();
        _reentrancyStatus = _ENTERED;
        _;
        _reentrancyStatus = _NOT_ENTERED;
    }

    // Require a non-zero ETH value in payable functions
    modifier nonZeroValue() {
        if (msg.value == 0) revert ZeroDeposit();
        _;
    }

    // ==============================
    // Constructor
    // ==============================

    constructor(uint256 _bankCap, uint256 _withdrawalLimit) {
        BANK_CAP = _bankCap;
        WITHDRAWAL_LIMIT = _withdrawalLimit;
        _reentrancyStatus = _NOT_ENTERED;
    }

    // ==============================
    // Deposit
    // ==============================

    /**
     * @notice Deposit ETH into your personal vault.
     */
    function deposit() external payable nonReentrant nonZeroValue {
        if (totalHeld + msg.value > BANK_CAP) revert BankCapReached();

        balances[msg.sender] += msg.value;
        totalHeld += msg.value;
        totalDepositCount++;
        userDepositCount[msg.sender]++;

        emit Deposit(msg.sender, msg.value, totalHeld);
    }

    // ==============================
    // Withdraw
    // ==============================

    /**
     * @notice Withdraw ETH respecting your balance and the limit per transaction.
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount > WITHDRAWAL_LIMIT) revert ExceedsWithdrawalLimit();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        totalHeld -= amount;
        totalWithdrawCount++;
        userWithdrawCount[msg.sender]++;

        _safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    // ==============================
    // View functions
    // ==============================

    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getUserStats(address user) external view returns (uint256 deposits, uint256 withdrawals) {
        return (userDepositCount[user], userWithdrawCount[user]);
    }

    // ==============================
    // Internal transfer
    // ==============================

    // Safe native ETH transfer using call
    function _safeTransfer(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // ==============================
    // Fallback
    // ==============================

    receive() external payable {
        revert("Direct deposits not allowed");
    }
}
