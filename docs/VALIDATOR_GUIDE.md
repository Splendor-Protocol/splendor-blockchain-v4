# Splendor Validator Guide

This comprehensive guide will help you become a validator on the Splendor Blockchain V4 mainnet and earn rewards through staking and block validation.

## Overview

Splendor uses a Congress consensus mechanism (enhanced Proof of Authority) with a tiered validator system that ensures fair participation and network security.

### Validator Tiers & Requirements

| Tier | Stake Requirement | USD Equivalent* | Benefits |
|------|------------------|-----------------|----------|
| **Bronze** | 3,947 SPLD | ~$1,500 | Entry-level validation |
| **Silver** | 39,474 SPLD | ~$15,000 | Enhanced rewards |
| **Gold** | 394,737 SPLD | ~$150,000 | Maximum rewards & voting power |

*USD equivalents are approximate and subject to market fluctuations

### Validator Economics

- **Fee Distribution**: 60% of gas fees go to validators
- **Staker Rewards**: 30% of gas fees distributed to stakers
- **Protocol Fund**: 10% of gas fees for development
- **Block Time**: ~1 second average
- **Uptime Requirement**: 99.9% minimum
- **Maximum Validators**: 10,000 network-wide

## Prerequisites

### Technical Requirements

#### Minimum System Requirements
- **Operating System**: Ubuntu 20.04 LTS or Windows Server 2019+
- **CPU**: 4 cores (Intel/AMD x64)
- **RAM**: 8GB
- **Storage**: 100GB high-speed SSD
- **Network**: Stable internet with <50ms latency
- **Uptime**: 24/7 operation capability

#### Recommended System Requirements
- **Operating System**: Ubuntu 22.04 LTS
- **CPU**: 8+ cores (Intel/AMD x64)
- **RAM**: 16GB+
- **Storage**: 500GB+ NVMe SSD
- **Network**: 1Gbps+ dedicated connection
- **Power**: UPS backup system
- **Monitoring**: Server monitoring tools

### Financial Requirements

- **Minimum Stake**: 3,947 SPLD for Bronze tier
- **Gas Fees**: Additional SPLD for transaction fees
- **Operating Costs**: Server hosting, electricity, internet
- **Emergency Fund**: Extra SPLD for unexpected expenses

## Step-by-Step Validator Setup

### Prerequisites

**⚠️ IMPORTANT: You must create a fresh wallet and have the Private Key - it will be needed for the validator setup!**

Before starting, ensure you have:
- A fresh wallet with private key access
- Minimum stake amount for your chosen tier (3,947 SPLD for Bronze, 39,474 SPLD for Silver, 394,737 SPLD for Gold)
- Server meeting the technical requirements listed above

### 1. Server Setup and Installation

#### Step 1: Switch to Root User
```bash
sudo -i
```

#### Step 2: Update and Upgrade System Packages
```bash
apt update && apt upgrade -y
```

#### Step 3: Install Required Packages
```bash
apt install -y git tar curl wget tmux
```

#### Step 4: Reboot the Server
```bash
reboot
```

#### Step 5: Switch to Root Again (After Reboot)
```bash
sudo -i
```

#### Step 6: Clone the Splendor Blockchain Repository
```bash
git clone https://github.com/Splendor-Protocol/splendor-blockchain-v4.git
```

#### Step 7: Navigate to Core-Blockchain Directory
```bash
cd splendor-blockchain-v4/Core-Blockchain
```

#### Step 8: Run the Validator Setup
```bash
./node-setup.sh --validator 1
```

**Important: Choose option 2 when prompted!**

#### Step 9: Start the Validator
```bash
./node-start.sh --validator
```

**Note: Ignore any PM2 errors - these are for RPC nodes and don't affect validator operation.**

#### Step 10: Attach to the Validator Session
```bash
tmux attach -t node1
```

#### Step 11: Wait for 'Unauthorized' Status
Wait until the output shows 'unauthorized'. This indicates the node is running but not yet authorized as a validator.

#### Step 12: Detach from Session (Keep Node Running)
To leave the node running in the background:
- Press `CTRL + b`
- Release both keys
- Press `d`

This detaches you from the tmux session while keeping the validator node running.

### 2. Register as Guardian/Validator

#### Step 1: Access the Dashboard
Go to [https://dashboard.splendor.org/](https://dashboard.splendor.org/)

#### Step 2: Connect Your Wallet
- Click "Become a Guardian"
- Connect the wallet that contains your SPLD tokens
- **Important**: This must be the same wallet whose private key you used during validator setup

#### Step 3: Choose Your Tier
- Select your desired tier (Silver recommended for most validators)
- Ensure you have sufficient SPLD tokens for the chosen tier
- Complete the staking process through the dashboard


## Validator Operations

### Monitoring Your Validator

#### Essential Metrics to Monitor

1. **Node Status**
   - Block height synchronization
   - Peer connections
   - Memory and CPU usage
   - Disk space availability

2. **Validator Performance**
   - Blocks produced
   - Missed blocks
   - Uptime percentage
   - Reward earnings

3. **Network Health**
   - Network latency
   - Transaction pool size
   - Gas price trends
   - Network congestion


### Maintaining Your Validator

#### Regular Maintenance Tasks

1. **Daily Checks**
   - Verify node is running and synced
   - Check system resources (CPU, RAM, disk)
   - Monitor network connectivity
   - Review logs for errors

2. **Weekly Tasks**
   - Update system packages
   - Check backup integrity
   - Review performance metrics
   - Analyze reward earnings

3. **Monthly Tasks**
   - Update node software (if available)
   - Security audit and updates
   - Hardware health check
   - Financial performance review


### Upgrading Your Validator

#### Software Updates

```bash
# Stop validator (gracefully)
# Send SIGTERM to geth process

# Backup current setup
cp -r data/ data-backup-$(date +%Y%m%d)/

# Pull latest changes
git pull origin main

# Rebuild node
npm run build-node

# Restart validator
# Use your startup script
```

#### Tier Upgrades

To upgrade from Bronze to Silver or Gold:

```javascript
// Stake additional tokens
const additionalStake = ethers.parseEther('35527'); // Bronze to Silver
await validatorsContract.stake({ value: additionalStake });
```

## Rewards and Economics

### Reward Structure

#### Block Rewards
- **Base Reward**: Fixed amount per block produced
- **Gas Fees**: 60% of transaction fees in blocks you validate
- **Tier Multiplier**: Higher tiers receive bonus multipliers

#### Staking Rewards
- **Compound Interest**: Rewards automatically compound
- **Performance Bonus**: Extra rewards for high uptime
- **Delegation Rewards**: Earn from tokens delegated to you

### Calculating Profitability

```javascript
// Example profitability calculation
const dailyBlocks = 86400; // ~1 second block time
const validatorCount = 100; // example
const blocksPerValidator = dailyBlocks / validatorCount;
const gasFeesPerBlock = 0.01; // example in SPLD
const dailyRewards = blocksPerValidator * gasFeesPerBlock;
const monthlyRewards = dailyRewards * 30;
const annualRewards = dailyRewards * 365;

console.log(`Estimated daily rewards: ${dailyRewards} SPLD`);
console.log(`Estimated monthly rewards: ${monthlyRewards} SPLD`);
console.log(`Estimated annual rewards: ${annualRewards} SPLD`);
```

### Tax Considerations

- **Staking Rewards**: May be taxable as income
- **Capital Gains**: Selling SPLD may trigger capital gains tax
- **Business Expenses**: Server costs may be deductible
- **Professional Advice**: Consult with tax professionals

## Security Best Practices

### Operational Security

1. **Key Management**
   - Use hardware security modules (HSM) for production
   - Never store private keys in plain text
   - Implement multi-signature setups where possible
   - Regular key rotation procedures

2. **Server Security**
   - Keep systems updated with security patches
   - Use firewall rules to limit access
   - Implement intrusion detection systems
   - Regular security audits

3. **Network Security**
   - Use VPN for remote access
   - Implement DDoS protection
   - Monitor for unusual network activity
   - Secure communication channels

### Slashing Protection

Avoid actions that can result in slashing:

1. **Double Signing**: Never run multiple validator instances with the same key
2. **Downtime**: Maintain 99.9% uptime to avoid penalties
3. **Malicious Behavior**: Follow protocol rules strictly

### Emergency Procedures

#### Node Failure Recovery

```bash
# Quick recovery steps
1. Identify the issue (hardware, software, network)
2. Switch to backup server if available
3. Restore from latest backup
4. Restart validator operations
5. Monitor for successful recovery
```

#### Slashing Response

If your validator is slashed:

1. **Immediate Actions**
   - Stop the validator to prevent further penalties
   - Investigate the cause of slashing
   - Fix any issues identified

2. **Recovery Process**
   - Wait for the jail period to expire
   - Submit unjail proposal if required
   - Restart validator operations
   - Implement additional safeguards

## Troubleshooting

### Common Issues

#### Node Won't Start

```bash
# Check logs
tail -f logs/geth.log

# Common solutions:
1. Check port availability (8545, 30303)
2. Verify account password
3. Ensure sufficient disk space
4. Check network connectivity
```

#### Sync Issues

```bash
# Force resync
./geth.exe removedb --datadir ./data
./geth.exe init genesis.json --datadir ./data
# Restart node
```

#### Performance Issues

```bash
# Monitor system resources
htop
df -h
iostat -x 1

# Optimize configuration
# Increase cache sizes
# Adjust peer limits
# Optimize disk I/O
```

### Getting Help

1. **Documentation**: Review all guides thoroughly
2. **Community**: Join Discord/Telegram for support
3. **GitHub Issues**: Report bugs and feature requests
4. **Professional Support**: Consider hiring blockchain consultants

## Advanced Topics

### Running Multiple Validators

```bash
# Use different data directories
./geth.exe --datadir ./validator1 --port 30303 --rpcport 8545
./geth.exe --datadir ./validator2 --port 30304 --rpcport 8546
```

### Load Balancing and High Availability

- **Multiple Servers**: Distribute load across servers
- **Failover Systems**: Automatic switching to backup nodes
- **Geographic Distribution**: Servers in multiple regions
- **Monitoring Systems**: 24/7 automated monitoring

### Custom Monitoring Solutions

```javascript
// Example monitoring script
const { ethers } = require('ethers');

async function monitorValidator() {
  const provider = new ethers.JsonRpcProvider('http://localhost:8545');
  
  // Check if node is synced
  const blockNumber = await provider.getBlockNumber();
  const networkBlock = await provider.getBlockNumber();
  
  if (blockNumber < networkBlock - 10) {
    console.log('⚠️ Node is behind, current:', blockNumber, 'network:', networkBlock);
  }
  
  // Check validator balance
  const balance = await provider.getBalance('0xYOUR_VALIDATOR_ADDRESS');
  console.log('Validator balance:', ethers.formatEther(balance), 'SPLD');
}

setInterval(monitorValidator, 60000); // Check every minute
```

## Conclusion

Running a Splendor validator is a rewarding but responsible endeavor. Success requires:

- **Technical Expertise**: Understanding blockchain technology and server management
- **Financial Commitment**: Significant stake and ongoing operational costs
- **Time Investment**: Regular monitoring and maintenance
- **Risk Management**: Understanding and mitigating various risks

By following this guide and maintaining best practices, you can contribute to the Splendor network's security and decentralization while earning rewards for your participation.

## Additional Resources

- [Getting Started Guide](GETTING_STARTED.md)
- [API Reference](API_REFERENCE.md)
- [Smart Contract Development](SMART_CONTRACTS.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Main Documentation](../README.md)

---

**⚠️ Important**: Validator operations involve financial risk. Only stake what you can afford to lose, and ensure you understand all risks before becoming a validator.
