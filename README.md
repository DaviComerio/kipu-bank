# KipuBank

KipuBank is a simple and secure Ethereum smart contract that allows each user to deposit and withdraw ETH with fixed limits.  
It was developed as part of the **Ethereum Developer Pack – Module 2** practical exam.

---

## 🔍 Contract Information

- **Network:** Sepolia Testnet  
- **Compiler Version:** 0.8.26
- **EVM Version:** Prague  
- **License:** MIT  
- **Contract Name:** `KipuBank`  
- **Transaction Hash:** [0x10bbcf67d73154f66b5f62fbbd4b03670a1189ec01e865a8bf270b658f27f8c1](https://sepolia.etherscan.io/tx/0x10bbcf67d73154f66b5f62fbbd4b03670a1189ec01e865a8bf270b658f27f8c1)  
- **Contract Address:** 0x5Cd6a8FbD72c85d740Df435502080c27CDE5C42F

---

## 💡 Description

Each user has their own personal vault to store ETH.  
The contract ensures safe and controlled interactions following Solidity best practices.

**Main features:**
- Per-user balances (stored in mappings)  
- Global bank capacity limit (`BANK_CAP`)  
- Withdrawal limit per transaction (`WITHDRAWAL_LIMIT`)  
- Custom errors for gas efficiency  
- Safe ETH transfer using low-level `call`  
- Reentrancy protection (`nonReentrant` modifier)  
- Events for each successful deposit and withdrawal  
- Clean code and NatSpec-style comments for clarity  

---

## ⚙️ How It Works

### 1. Deposit ETH
Users can send ETH to their personal vault using the `deposit()` function.  
If the total cap is reached or value is zero, the transaction reverts.

### 2. Withdraw ETH
Users can withdraw their ETH using the `withdraw(amount)` function.  
Withdrawals are limited by `WITHDRAWAL_LIMIT`.

### 3. View Balances
Functions like `getMyBalance()` and `getBalance(address)` allow users to check balances.

---

## 🧠 Technical Overview

| Component | Description |
|------------|--------------|
| **Immutable Variables** | `BANK_CAP`, `WITHDRAWAL_LIMIT` |
| **Storage Variables** | `totalHeld`, `totalDepositCount`, `totalWithdrawCount` |
| **Mappings** | `balances`, `userDepositCount`, `userWithdrawCount` |
| **Modifiers** | `nonReentrant`, `nonZeroValue` |
| **Custom Errors** | `BankCapReached`, `ZeroDeposit`, `ExceedsWithdrawalLimit`, `InsufficientBalance`, `ReentrantCall` |
| **Events** | `Deposit`, `Withdrawal` |
| **Functions** | `deposit`, `withdraw`, `getMyBalance`, `getBalance`, `getUserStats` |
| **Private Function** | `_safeTransfer` (safe native transfer) |
| **Fallback** | Rejects direct transfers |

---

## 🚀 How to Deploy (using Remix + MetaMask)

1. Open **[Remix IDE](https://remix.ethereum.org)**  
2. Paste the contract into `contracts/KipuBank.sol`
3. Compile with:
   - Solidity version: **0.8.26**
   - Optimization: ✅ Enabled
   - EVM: **Paris**
4. Go to the **Deploy & Run Transactions** tab:
   - Environment: **Injected Provider (MetaMask – Sepolia)**
   - Enter constructor parameters:
     ```
     _bankCap = 100
     _withdrawalLimit = 10
     ```
   - Click **Deploy**
   - Confirm the transaction in MetaMask
5. Once mined, copy the **contract address** shown in the Remix console
6. Verify the contract on [Sepolia Etherscan](https://sepolia.etherscan.io)

---

## 🧱 Example Interaction

- Deposit:  
  `deposit()` → send ETH value with transaction  
- Withdraw:  
  `withdraw(0.5 ether)` → withdraw up to the defined limit  
- View your balance:  
  `getMyBalance()`

---

## 🧾 Author

**Name:** Davi Henrique Comério  
**Course:** Ethereum Developer Pack – Module 2  
**Year:** 2025  
**Language:** Solidity  

---

## 🏁 Verification Link (after publish)
Once verified, your contract will appear as:

✅ *“Contract Source Code Verified”*  
on [Sepolia Etherscan](https://sepolia.etherscan.io).
