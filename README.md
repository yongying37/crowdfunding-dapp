# Decentralised Crowdfunding DApp on BNB Smart Chain

> BAC2002 Blockchain & Cryptocurrency — Team Project  
> Milestone-based crowdfunding using smart contracts

---

## 📌 Overview

This project is a decentralised crowdfunding platform deployed on **BNB Smart Chain Testnet (Chain ID 97)**.

The system ensures:

- Funds are stored securely in a smart contract (escrow)
- Campaign creators cannot withdraw funds directly
- Funds are released only after **majority approval from backers**
- If funding fails, backers can **claim refunds**

---

## 🏗 Architecture

Frontend:

- HTML + Vanilla JavaScript
- ethers.js v6
- MetaMask wallet integration

Backend:

- Solidity smart contract deployed on BSC Testnet

---

## 🔑 Key Features

| Feature                 | Description                         |
| ----------------------- | ----------------------------------- |
| Decentralised funding   | No central authority controls funds |
| Milestone-based release | Funds released in stages            |
| Backer voting           | Majority approval required          |
| Refund mechanism        | If goal not reached                 |
| Multilateral backers    | Multiple users contribute           |

---

## 👥 Multilateral Backers

The system supports multiple contributors per campaign.

```solidity
mapping(uint256 => mapping(address => uint256)) contributions;
```

- Each backer’s contribution is tracked individually
- Backers participate in milestone voting
- Ensures fairness and transparency

## 🗳 Voting Mechanism

```solidity
approvalCount * 2 > backerCount
```

- More than 50% approval required
- Prevents premature withdrawal of funds
- Fully enforced on-chain

## 🔍 Transaction Verification

All interactions are recorded on-chain and can be verified via BscScan:

- Campaign creation → CampaignCreated
- Contributions → ContributionMade
- Goal reached → GoalReached
- Voting → MilestoneVoted
- Fund release → MilestoneReleased
- Refund → RefundIssued

Transaction links are provided in:

```
docs/txn-links.md
```

## 📁 Project Structure

```
crowdfunding-dapp/
├── contracts/
│ └── CrowdFund.sol
├── scripts/
│ └── deploy.js
├── frontend/
│ └── index.html
├── docs/
│ └── txn-links.md
├── hardhat.config.js
├── package-lock.json
├── package.json
└── README.md
```

## 🚀 Setup & Deployment

### Prerequisites

- Node.js v18+
- MetaMask with BNB Smart Chain Testnet added (Chain ID 97)
- tBNB test tokens from the faucet

### 1. Clone the Repository

```bash
git clone https://github.com/yongying37/crowdfunding-dapp.git
cd crowdfunding-dapp
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure Environment

Create a `.env` file in the root folder (do NOT commit this):

```env
PRIVATE_KEY=your_metamask_private_key_here
BSC_RPC=https://bsc-testnet-rpc.publicnode.com/
```

> **Get tBNB:** Visit https://testnet.bnbchain.org/faucet-smart

### 4. Compile

```bash
npx hardhat compile
```

### 5. Deploy to BSC Testnet

```bash
npx hardhat run scripts/deploy.js --network bscTestnet
```

Copy the deployed contract address from the terminal output.

### 6. Run Frontend

Open `frontend/index.html` using Live Server in VS Code.

Then:

1. Connect MetaMask
2. Ensure MetaMask is on BNB Smart Chain Testnet
3. Paste the deployed contract address
4. Interact with the DApp

Make sure MetaMask is connected to **BNB Smart Chain Testnet (Chain ID 97)**.

## 🎥 Demo Video

[Watch Crowdfunding DApp Demo Video](./CrowdfundDappDemo.mp4)

## 👥 Team

Team 12

Members: Ang Xuan Yu Pamela, Siew Yong Ying, Tay Xin Ying, Teo Shao Xuan, Vanessa Quan Hui Si

Singapore Institute of Technology  

Module: BAC2002 - Blockchain and Cryptocurrency
