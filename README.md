# KipuBank

KipuBank is a simple secure smart contract that allows each user to deposit and withdraw ETH with strict limits.

## Features
- **Personal vaults:** each user has their own balance.
- **Global bank cap:** the contract rejects deposits once a total cap is reached.
- **Withdrawal limit:** users can withdraw only up to a fixed amount per transaction.
- **Custom errors:** replaces `require` strings for gas efficiency.
- **Safe ETH transfers:** uses low-level `call` with success checks.
- **Events:** emitted on successful deposits and withdrawals.
- **Reentrancy protection:** implemented with a simple guard.
- **NatSpec documentation:** clean and professional comments.

## Functions
| Function | Visibility | Description |
|-----------|-------------|--------------|
| `deposit()` | external payable | Deposit ETH into personal vault |
| `withdraw(uint256 amount)` | external | Withdraw ETH respecting per-tx limit |
| `getBalance(address who)` | external view | View any user’s stored balance |
| `getMyBalance()` | external view | View caller’s balance |

## Constructor Parameters
```solidity
constructor(uint256 _bankCap, uint256 _withdrawalLimit)
