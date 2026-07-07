<p align="center">
  <img src="https://img.shields.io/badge/Quanta-AgentPay-0052FF?style=for-the-badge" alt="Quanta AgentPay">
  <img src="https://img.shields.io/badge/Release-v0.1.0-black?style=for-the-badge" alt="Release v0.1.0">
  <img src="https://img.shields.io/badge/Network-Base%20Sepolia-0052FF?style=for-the-badge" alt="Base Sepolia">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Contracts-EVM-627EEA?style=flat-square" alt="EVM Contracts">
  <img src="https://img.shields.io/badge/SDK-TypeScript-3178C6?style=flat-square" alt="TypeScript SDK">
  <img src="https://img.shields.io/badge/Tests-176%20Passing-2EA44F?style=flat-square" alt="176 tests passing">
  <img src="https://img.shields.io/badge/Status-Testnet%20Experimental-F59E0B?style=flat-square" alt="Testnet Experimental">
</p>

<h1 align="center">Quanta v0.1.0</h1>

<p align="center">
  <strong>AgentPay Testnet Release</strong>
</p>

<p align="center">
  Open-source payment and trust layer for autonomous AI agents.
</p>

<p align="center">
  <strong>Wallets with rules for AI agents.</strong>
</p>

---

## Overview

Quanta v0.1.0 is the first public testnet release of the AgentPay stack.

This release includes:

- EVM smart contracts
- TypeScript SDK
- AgentPay dashboard demo
- Base Sepolia deployment
- Real-wallet test flow
- On-chain spending policy and receipt flow

The goal is simple:

AI agents should not just have wallets.  
They need budgets, permissions, spend limits, authorized spenders, and on-chain receipts.

---

## What is included

### Smart contracts

- QuantaToken ERC-20
- AIAgentRegistry for agent identity, spending policies, and authorized spenders
- AIPaymentChannel payment channel primitive
- AIModelMarketplace model and data marketplace primitives

### Developer tools

- TypeScript SDK
- AgentPay dashboard demo
- Mock mode for simple demos
- Real mode for Base Sepolia testing
- Public deployment records

### Testing status

- 176 Solidity tests passing
- SDK build passing
- SDK audit passing
- AgentPay dashboard build passing
- AgentPay dashboard typecheck passing
- Base Sepolia real-wallet test completed

---

## Base Sepolia deployment

Network:

```text
Base Sepolia
Chain ID: 84532
