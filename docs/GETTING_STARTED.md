# Getting Started with Splendor Blockchain V4

This guide will help you get up and running with the Splendor Blockchain V4 mainnet quickly.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v16 or higher) - [Download here](https://nodejs.org/)
- **Go** (v1.15 or higher) - [Download here](https://golang.org/dl/)
- **npm** (comes with Node.js) or **yarn**
- **Git** - [Download here](https://git-scm.com/)

## Step-by-Step Setup

### 1. Clone and Install

```bash
# Clone the repository
git clone https://github.com/Splendor-Protocol/splendor-blockchain-v4.git
cd splendor-blockchain-v4

# Install root dependencies
npm install

# Install system contracts dependencies
npm run setup
```

### 2. Build the Node

```bash
# Build the blockchain node
npm run build-node
```

### 3. Initialize Genesis

```bash
# Initialize the blockchain with genesis block
npm run init-genesis
```

### 4. Verify Connection

```bash
# Test connection to mainnet
npm run verify
```

You should see output similar to:
```
🚀 Splendor Mainnet Verification Script
====================================

1. Testing network connection...
   ✅ Connected to network with Chain ID: 2691

2. Checking current block...
   ✅ Current block number: 12345

...

🎉 All tests passed! Splendor Mainnet is working correctly.
```

## What's Available?

When you connect to the mainnet, the following services are available:

- **Mainnet RPC**: Available at `https://mainnet-rpc.splendor.org/`
- **Block Explorer**: Available at `https://explorer.splendor.org/`
- **Chain ID**: 2691
- **Currency**: SPLD tokens

## Running Your Own Node

### Validator Node

To run as a validator (requires staking):

```bash
# Create validator account
cd Core-Blockchain
./geth.exe account new --datadir ./data

# Start validator node
npm run start-validator
```

### RPC Node

To run as an RPC node (no staking required):

```bash
# Setup RPC node
cd Core-Blockchain
./node-setup.sh --rpc

# Start RPC node
./node-start.sh --rpc
```

For detailed RPC setup instructions, see the [RPC Setup Guide](RPC_SETUP_GUIDE.md).

## Next Steps

1. **Connect MetaMask**: Follow the [MetaMask Setup Guide](METAMASK_SETUP.md)
2. **Deploy Contracts**: See the [Smart Contract Development Guide](SMART_CONTRACTS.md)
3. **Become a Validator**: Check out the [Validator Guide](VALIDATOR_GUIDE.md)
4. **Setup RPC Node**: See the [RPC Setup Guide](RPC_SETUP_GUIDE.md)
5. **Explore APIs**: Check out the [API Reference](API_REFERENCE.md)

## Common Commands

```bash
# Verify mainnet connection
npm run verify

# Compile system contracts
npm run compile-contracts

# Deploy contracts to mainnet
npm run deploy-contracts

# Build the node from source
npm run build-node
```

## System Requirements

### Validator Nodes
- **Operating System**: Ubuntu >= 20.04 LTS (recommended) or Windows Server 2019+
- **CPU**: 4 cores minimum (Intel/AMD x64) - 8 cores recommended
- **RAM**: 8GB minimum - 16GB recommended
- **Storage**: 100GB high-speed SSD - 500GB NVMe recommended
- **Network**: Stable internet with <50ms latency - 1Gbps recommended

### RPC Nodes
- **Operating System**: Ubuntu >= 20.04 LTS (recommended) or Windows Server 2019+
- **CPU**: 8 cores minimum - 16 cores recommended
- **RAM**: 16GB minimum - 32GB recommended
- **Storage**: 200GB high-speed SSD - 1TB NVMe recommended
- **Network**: High-bandwidth internet connection - 10Gbps recommended

## Troubleshooting

### Connection Issues

If you can't connect to the mainnet:

1. **Check Internet Connection**: Ensure you have stable internet
2. **Verify RPC Endpoint**: Test `https://mainnet-rpc.splendor.org/` accessibility
3. **Firewall Settings**: Ensure ports are not blocked
4. **DNS Issues**: Try using a different DNS server

### Node Won't Start

1. Check if required ports are available
2. Ensure you have sufficient disk space
3. Verify Go and Node.js versions
4. Check system requirements

### Build Issues

1. **Go Version**: Ensure Go 1.15+ is installed
2. **Dependencies**: Run `go mod tidy` in the node_src directory
3. **Permissions**: Ensure you have write permissions
4. **Path Issues**: Verify Go is in your system PATH

## Need Help?

- Check the main [README.md](../README.md)
- Review the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Join our community Discord
- Create an issue in the repository

## Security Notes

- **Never share private keys**
- **Use hardware wallets for large amounts**
- **Keep your node software updated**
- **Monitor your validator performance**
- **Use secure connections only**
