# Splendor RPC Blockchain Deployment Guide

This guide provides comprehensive instructions for deploying the Splendor RPC blockchain with the tiered validator system.

## Overview

Splendor RPC is a DPoS (Delegated Proof of Stake) blockchain with the following key features:

- **Chain ID**: 2691
- **Network Name**: Splendor RPC
- **RPC URL**: https://mainnet-rpc.splendor.org
- **Initial Supply**: 26,000,000,000 SPLD (26 billion tokens)
- **Tiered Validator System**: Bronze, Silver, Gold tiers
- **Fair Fee Distribution**: 60% Validators, 30% Stakers, 10% Protocol Development

## Validator Tiers

### Bronze Tier (Entry Level)
- **Minimum Stake**: 3,947 SPLD (~$1,500)
- **Target**: New validators and smaller participants

### Silver Tier (Mid Level)
- **Minimum Stake**: 39,474 SPLD (~$15,000)
- **Target**: Committed validators with higher investment

### Gold Tier (Premium Level)
- **Minimum Stake**: 394,737 SPLD (~$150,000)
- **Target**: Major validators and institutional participants

## Fee Distribution

- **60%** to Validators (infrastructure operators)
- **30%** to Stakers (delegators)
- **10%** to Protocol Development (`0xbab18a9522d82E4B6583197ea16fe4b3Bbf360bE`)

## Pre-Deployment Checklist

### 1. Core Blockchain Configuration
- [x] Chain ID set to 2691
- [x] Genesis file configured with 26B initial supply
- [x] Minting address set to `0xF5BBDF432EcCCeF7eD8E96D643edB26D76390C84`
- [x] Congress consensus parameters configured (1s block time, 200 block epochs)

### 2. System Contracts
- [x] Validators contract with tiered system implemented
- [x] Params contract with tier constants defined
- [x] Punish contract for validator penalties
- [x] Proposal contract for governance
- [x] All burn-related code removed
- [x] Owner fee distribution to fixed address

### 3. Contract Addresses (Pre-deployed)
- **Validators**: `0x000000000000000000000000000000000000f000`
- **Punish**: `0x000000000000000000000000000000000000F001`
- **Proposal**: `0x000000000000000000000000000000000000F002`

## Deployment Steps

### Step 1: Prepare Environment

1. **Server Requirements**:
   - Ubuntu 20.04+ LTS
   - 8GB RAM minimum (32GB recommended)
   - 100GB SSD storage minimum
   - Stable internet connection

2. **Install Dependencies**:
   ```bash
   sudo apt update && sudo apt upgrade
   sudo apt install git tar curl wget build-essential
   ```

### Step 2: Deploy Core Blockchain

1. **Clone Repository**:
   ```bash
   https://github.com/Splendor-Protocol/splendor-blockchain-v4.git
   cd splendor-blockchain-v4/Core-Blockchain
   ```

2. **Setup Validator Node**:
   ```bash
   ./node-setup.sh --validator 1
   source ~/.bashrc
   ```

3. **Start Node**:
   ```bash
   ./node-start.sh --validator
   ```

### Step 3: Deploy System Contracts

1. **Navigate to System Contracts**:
   ```bash
   cd ../System-Contracts
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment**:
   - Update `.env` file with deployment private key
   - Ensure hardhat.config.js points to correct network

4. **Compile Contracts**:
   ```bash
   npx hardhat compile
   ```

5. **Deploy Contracts** (if needed):
   ```bash
   npx hardhat run scripts/deploy.js --network splendor
   ```

### Step 4: Initialize Validator Set

1. **Access Node Console**:
   ```bash
   tmux attach -t node1
   ```

2. **Initialize with Genesis Validators**:
   - The genesis file already contains the initial validator configuration
   - System contracts are pre-deployed and initialized

### Step 5: Verification

1. **Check Node Status**:
   - Verify node is syncing/mining blocks
   - Check for "🔨 mined potential block" messages

2. **Verify Contract Deployment**:
   ```bash
   npx hardhat verify --network splendor <contract_address>
   ```

3. **Test Validator Creation**:
   - Use staking interface at https://staking.splendor-rpc.org/
   - Test with minimum Bronze tier amount (3,947 SPLD)

## Configuration Files Summary

### Core Blockchain Files
- `genesis.json`: Initial blockchain state with 26B supply
- `readme.md`: Updated documentation with tier information

### System Contract Files
- `contracts/Validators.sol`: Main validator contract with tier system
- `contracts/Params.sol`: System parameters and tier constants
- `hardhat.config.js`: Deployment configuration
- `README.md`: Contract documentation

## Key Parameters

### Blockchain Parameters
- **Block Time**: 1 second (faster blocks for improved performance)
- **Epoch Length**: 200 blocks
- **Max Validators**: 10,000
- **Staking Lock Period**: 86,400 blocks
- **Selective Rewards**: Only owner-approved validators receive extra rewards

### Tier Thresholds
- **Bronze**: 3,947 SPLD (0xD5D238A4ABE98000000)
- **Silver**: 39,474 SPLD (0x8AC7230489E80000000)
- **Gold**: 394,737 SPLD (0x56BC75E2D630EB0000000)

### Fee Distribution
- **Validator Share**: 60% (60000/100000)
- **Staker Share**: 30% (30000/100000)
- **Owner Share**: 10% (10000/100000)
- **Owner Address**: `0xbab18a9522d82E4B6583197ea16fe4b3Bbf360bE`

## Post-Deployment Tasks

### 1. Network Configuration
- Update RPC endpoints
- Configure block explorers
- Set up monitoring systems

### 2. Staking Interface
- Deploy staking web interface
- Configure tier display
- Test validator creation flow

### 3. Documentation Updates
- Update API documentation
- Create validator guides
- Publish tier information

### 4. Validator Reward Management
- **Two-Tier Reward System**: 
  - **Base Fee Distribution**: ALL validators automatically receive their share of gas fees (60% validators, 30% stakers, 10% protocol)
  - **Extra Rewards**: Only admin-approved validators receive additional rewards from the ValidatorHelper contract
- **Multi-Admin System**: Owner can add multiple admins to manage validator rewards and transfers
- **Admin Functions** (Owner + Admins):
  - `setValidatorRewardApproval(address validator, bool approved)`: Approve/disapprove individual validators
  - `setMultipleValidatorRewardApproval(address[] validators, bool approved)`: Batch approve validators
  - `distributeRewardsToApproved()`: Manually distribute rewards to approved validators
  - `transferFunds(address to, uint256 amount)`: Transfer funds from contract
- **Owner-Only Functions**:
  - `addAdmin(address newAdmin)`: Add new admin
  - `removeAdmin(address admin)`: Remove admin (cannot remove owner)
  - `emergencyTransfer(address to, uint256 amount)`: Emergency fund transfer
- **View Functions**:
  - `getApprovedValidators()`: Get list of approved validators
  - `isValidatorApprovedForRewards(address validator)`: Check approval status
  - `getApprovedValidatorsCount()`: Get count of approved validators
  - `getAdminList()`: Get list of all admins
  - `isAdmin(address account)`: Check if address is admin
  - `getAdminCount()`: Get total admin count

## Troubleshooting

### Common Issues

1. **Node Won't Start**:
   - Check genesis file format
   - Verify system requirements
   - Check port availability

2. **Contract Deployment Fails**:
   - Verify network configuration
   - Check account balance
   - Confirm gas settings

3. **Validator Creation Issues**:
   - Ensure minimum staking amount
   - Check contract addresses
   - Verify network connection

### Support Resources
- GitHub Issues: [Repository Issues Page]
- Documentation: Updated README files
- Community: [Community Channels]

## Security Considerations

1. **Private Key Management**:
   - Use hardware wallets for production
   - Implement key rotation policies
   - Secure backup procedures

2. **Network Security**:
   - Configure firewalls properly
   - Use VPN for sensitive operations
   - Monitor for unusual activity

3. **Contract Security**:
   - Contracts have been audited for tier system
   - No burn mechanisms to prevent token loss
   - Fixed owner address prevents manipulation

## Conclusion

The Splendor RPC blockchain is now ready for deployment with:
- ✅ Tiered validator system (Bronze/Silver/Gold)
- ✅ Fair fee distribution model
- ✅ No token burning mechanism
- ✅ Scalable architecture (up to 10,000 validators)
- ✅ Complete documentation
- ✅ Deployment-ready configuration

All components have been tested and configured for production deployment.
