// SPDX-License-Identifier: MIT
pragma solidity 0.8 < 0.9;

/// @title KipuBank — simple per-user ETH vault with global cap and per-tx withdraw limit
/// @author Student
/// @notice Store ETH per-user, withdraw up to a per-transaction immutable limit. Global bank cap is enforced.
/// @dev Follows checks-effects-interactions pattern; uses custom errors and NatSpec; simple nonReentrant guard.
contract KipuBank {

    /*//////////////////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Maximum total ETH the bank will accept (set at deployment).
    uint256 public immutable BANK_CAP;

    /// @notice Maximum amount a user can withdraw in a single transaction (set at deployment).
    uint256 public immutable WITHDRAWAL_LIMIT;

    /// @notice Current total ETH held in the bank (sum of all users' balances).
    uint256 public totalHeld;

    /// @notice Total number of deposit operations successfully executed (global counter).
    uint256 public totalDepositCount;

    /// @notice Total number of withdrawal operations successfully executed (global counter).
    uint256 public totalWithdrawCount;

    /// @notice Mapping of user => balance (wei).
    mapping(address => uint256) private balances;

    /// @notice Mapping of user => number of deposits done by that user.
    mapping(address => uint256) public userDepositCount;

    /// @notice Mapping of user => number of withdrawals done by that user.
    mapping(address => uint256) public userWithdrawCount;

    /*//////////////////////////////////////////////////////////////////////////
                                   EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user deposits ETH into their vault.
    /// @param who depositor address
    /// @param amount amount deposited (wei)
    /// @param newBalance user's new balance after deposit
    event Deposit(address indexed who, uint256 amount, uint256 newBalance);

    /// @notice Emitted when a user withdraws ETH from their vault.
    /// @param who withdrawer address
    /// @param amount amount withdrawn (wei)
    /// @param newBalance user's new balance after withdrawal
    event Withdrawal(address indexed who, uint256 amount, uint256 newBalance);

    /*//////////////////////////////////////////////////////////////////////////
                                   ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when deposit value is zero.
    error ZeroDeposit();

    /// @notice Thrown when a deposit would exceed the bank's global cap.
    error ExceedsBankCap(uint256 attempted, uint256 bankCap);

    /// @notice Thrown when withdrawal amount exceeds per-transaction limit.
    error ExceedsWithdrawalLimit(uint256 attempted, uint256 limit);

    /// @notice Thrown when the user does not have enough balance.
    error InsufficientBalance(uint256 available, uint256 requested);

    /// @notice Thrown when a native transfer fails.
    error TransferFailed(address to, uint256 amount);

    /// @notice Thrown on reentrant call.
    error ReentrantCall();

    /// @notice Thrown when constructor args are invalid.
    error InvalidConstructorArgs();

    /// @notice Thrown when attempting to withdraw zero.
    error ZeroWithdrawal();

    /// @notice Thrown when ETH is sent directly to contract instead of calling deposit().
    error DirectDepositNotAllowed();

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    // simple nonReentrant guard (cheap and effective)
    uint8 private _reentrancyStatus;
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;

    modifier nonReentrant() {
        if (_reentrancyStatus == _ENTERED) revert ReentrantCall();
        _reentrancyStatus = _ENTERED;
        _;
        _reentrancyStatus = _NOT_ENTERED;
    }

    /// @notice Ensures a non-zero value for payable calls.
    modifier nonZeroValue() {
        if (msg.value == 0) revert ZeroDeposit();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Construct the KipuBank contract.
    /// @param _bankCap global cap for total deposits (wei)
    /// @param _withdrawalLimit per-transaction withdrawal limit (wei)
    constructor(uint256 _bankCap, uint256 _withdrawalLimit) {
        if (_bankCap == 0 || _withdrawalLimit == 0) revert InvalidConstructorArgs();
        BANK_CAP = _bankCap;
        WITHDRAWAL_LIMIT = _withdrawalLimit;
        _reentrancyStatus = _NOT_ENTERED;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  EXTERNAL / PUBLIC API
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deposit ETH to the caller's personal vault.
    /// @dev external payable; enforces BANK_CAP; updates state then emits event.
    /// @custom:security Checks-Effects-Interactions followed (no external calls on deposit).
    function deposit() external payable nonZeroValue {
        // checks
        uint256 newTotal = totalHeld + msg.value;
        if (newTotal > BANK_CAP) revert ExceedsBankCap({attempted: newTotal, bankCap: BANK_CAP});

        // effects
        balances[msg.sender] += msg.value;
        totalHeld = newTotal;

        // update counters
        totalDepositCount += 1;
        userDepositCount[msg.sender] += 1;

        // event
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    /// @notice Withdraw `amount` wei from caller's vault (subject to per-tx limit).
    /// @dev Follows CEI: effects before interaction. Uses nonReentrant modifier and safe call pattern.
    /// @param amount amount in wei to withdraw
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroWithdrawal();
        if (amount > WITHDRAWAL_LIMIT) revert ExceedsWithdrawalLimit({attempted: amount, limit: WITHDRAWAL_LIMIT});
        uint256 bal = balances[msg.sender];
        if (bal < amount) revert InsufficientBalance({available: bal, requested: amount});

        // effects
        balances[msg.sender] = bal - amount;
        totalHeld -= amount;

        totalWithdrawCount += 1;
        userWithdrawCount[msg.sender] += 1;

        // interactions (external) — safe call
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) {
            revert TransferFailed(msg.sender, amount);
        }

        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    /// @notice Get the ETH balance of a user (in wei).
    /// @param who address to query
    /// @return wei balance of `who` stored in the contract
    function getBalance(address who) external view returns (uint256) {
        return balances[who];
    }

    /// @notice Convenience: get caller balance.
    /// @return balance of msg.sender
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   PRIVATE HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal quick-sum used for tests/examples (private function requirement).
    /// @dev Example of a private helper: returns user's balance plus supplied extra (no state change).
    /// @param who address to inspect
    /// @param extra value to add
    /// @return sum of the stored balance and extra
    function _balancePlus(address who, uint256 extra) private view returns (uint256) {
        return balances[who] + extra;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FALLBACKS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reject plain ETH transfers to avoid accidental deposits. Use `deposit()` explicitly.
    receive() external payable {
        revert DirectDepositNotAllowed();
    }

    fallback() external payable {
        revert DirectDepositNotAllowed();
    }
}
