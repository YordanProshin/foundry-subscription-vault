# Foundry Subscription Vault

Smart contract infrastructure for handling subscription-based payments and access control on Ethereum-compatible blockchains.

---

##  Table of Contents

- [Foundry Subscription Vault](#foundry-subscription-vault)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [Features](#features)
    - [Prerequisites](#prerequisites)
    - [Clone \& Build](#clone--build)

---

##  About
Subscription Vault is a robust smart contract library designed to implement subscription-based payment systems on blockchain networks. Built with Foundry and Solidity ^0.8.24, this library provides a secure, gas-efficient foundation for developers to build subscription-based business models that operate without intermediaries.

This project was developed with a focus on simplicity, security, and flexibility - allowing businesses to implement subscription models with customizable billing cycles, automatic renewals, and seamless integration with blockchain payments.

"The future of digital services is subscription-based, and blockchain enables these subscriptions to be truly user-owned." - Yordan Proshin

---

##  Features

- **Flexible Subscription Periods :** Support for daily, weekly, monthly, and custom billing cycles 
- **Automated Renewals:**  Smart contracts automatically handle subscription renewals
- **Zero-Trust Architecture:** No need to trust intermediaries with payment processing
- **Gas Optimization:** Carefully engineered to minimize transaction costs
- **Pause/Cancel Functionality:** Subscribers can manage their subscriptions freely
- **Payment Flexibility:** Supports multiple payment tokens (EVM-compatible)
- **Event Logging:** Comprehensive event tracking for analytics and UI updates
- **Testing Suite:** Comprehensive Foundry tests covering all edge cases
- **Upgrade Safely:** Designed with potential future upgrades in mind

---

### Prerequisites

- Foundry (or use curl -L https://foundry.paradigm.xyz | bash)
- Node.js v16 or higher
- Yarn or npm

---

### Clone & Build

git clone https://github.com/yordanproshin/subscription-vault.git
cd subscription-vault
forge build