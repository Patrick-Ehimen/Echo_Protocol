# On-Chain Copy Trading Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.0-lightgrey)

A decentralized protocol enabling real-time copy trading on Uniswap V3/V4 with non-custodial vault management.

## Table of Contents

- [Protocol Overview](#protocol-overview)
- [Architecture](#architecture-overview)
- [Key Features](#key-features)
- [Technical Specs](#technical-specifications)
- [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [License](#license)

## Protocol Overview

The On-Chain Copy Trading Protocol allows users to:

- **Traders**: Create vaults and execute trades on Uniswap
- **Followers**: Copy trades proportionally in real-time
- **Earn Fees**: Traders earn performance fees, protocol collects transaction fees

Built with security-first principles using:

- Non-custodial vault architecture
- Reentrancy-protected contracts
- Chainlink-powered price oracles
- Dynamic slippage controls

## Architecture Overview

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#fff'}}}%%
flowchart TD
    classDef trader fill:#4CAF50,color:white
    classDef follower fill:#2196F3,color:white
    classDef contract fill:#607D8B,color:white
    classDef uniswap fill:#FF9800,color:black
    classDef security fill:#F44336,color:white
    classDef fees fill:#9C27B0,color:white

    subgraph Traders
        A([Trader]):::trader --> B[[Trader Vault]]:::contract
    end

    subgraph ProtocolCore
        B --> C[[Proxy Contract]]
        C --> D{Uniswap\nV3/V4}:::uniswap
        C --> E[[Trade Mirroring\nContract]]:::contract
        E --> F[[Fee Manager]]:::fees
    end

    subgraph Followers
        G([Follower]):::follower --> H[[Follower Vault]]:::contract
        E --> H
    end

    subgraph SecurityLayer
        I[[Oracle/Relayer]]:::security -->|Price Feed| C
        J[[Emergency\nPause]]:::security -->|Circuit Breaker| E
    end

    D -->|Swap Execution| B
    E -->|Copy Trade| H
    F -->|Protocol Fees| K[[Treasury]]:::fees
    F -->|Trader Fees| B

    style A stroke:#2E7D32,stroke-width:2px
    style G stroke:#1565C0,stroke-width:2px
    style D stroke:#EF6C00,stroke-width:2px
    style I stroke:#C62828,stroke-width:2px
    style K stroke:#6A1B9A,stroke-width:2px

linkStyle 0,1,2,3,4,5,6,7,8 stroke:#636,stroke-width:4px
```

### Key Features

#### Core Components

- Trader Vault: Non-custodial fund pool for strategy execution
- Follower Vault: Isolated vault for copied positions
- Proxy Contract: Unified interface for Uniswap interactions
- Trade Mirroring: Real-time proportional trade replication

#### For Traders

- Performance fee setting (0-20%)
- Historical trade analytics
- Follower growth dashboard
- Risk parameter configuration

#### For Followers

- 1-click copy trading
- Multiple trader following
- Stop-loss protection
- Gas-optimized execution
