# Splendor Blockchain Troubleshooting Guide

This comprehensive troubleshooting guide will help you resolve common issues when working with Splendor Blockchain V4.

## Quick Diagnostic Checklist

Before diving into specific issues, run through this quick checklist:

- [ ] Internet connection is stable
- [ ] Using correct network (Chain ID 2691 for mainnet)
- [ ] Node.js v16+ and Go v1.15+ are installed
- [ ] Sufficient SPLD tokens for gas fees
- [ ] Firewall/antivirus not blocking connections
- [ ] Using latest version of tools and software

## Network Connection Issues

### Cannot Connect to Mainnet

**Symptoms:**
- Connection timeout errors
- "Network unreachable" messages
- RPC calls failing

**Solutions:**

1. **Verify RPC Endpoint**
   ```bash
   # Test the RPC endpoint
   curl -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        https://mainnet-rpc.splendor.org/
     https://mainnet-rpc.splendor.org/
   
   # Expected response: {"jsonrpc":"2.0","id":1,"result":"0xa83"}
   ```

2. **Check DNS Resolution**
   ```bash
   # Windows
   nslookup mainnet-rpc.splendor.org
   
   # Linux/macOS
   dig mainnet-rpc.splendor.org
   ```

3. **Test with Different DNS**
   - Try Google DNS: 8.8.8.8, 8.8.4.4
   - Try Cloudflare DNS: 1.1.1.1, 1.0.0.1

4. **Firewall Configuration**
   ```bash
   # Windows Firewall
   # Allow outbound HTTPS (port 443)
   
   # Linux iptables
   sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
   ```

### Slow Network Performance

**Symptoms:**
- Long response times
- Timeouts on large requests
- Intermittent connection drops

**Solutions:**

1. **Use Connection Pooling**
   ```javascript
   const { ethers } = require('ethers');
   
   // Configure provider with connection pooling
   const provider = new ethers.JsonRpcProvider('https://mainnet-rpc.splendor.org/', {
     staticNetwork: ethers.Network.from(2691),
     batchMaxCount: 10,
     batchMaxSize: 1024 * 1024,
     batchStallTime: 10
   });
   ```

2. **Implement Retry Logic**
   ```javascript
   async function retryRpcCall(call, maxRetries = 3) {
     for (let i = 0; i < maxRetries; i++) {
       try {
         return await call();
       } catch (error) {
         if (i === maxRetries - 1) throw error;
         await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
       }
     }
   }
   ```

3. **Optimize Batch Requests**
   ```javascript
   // Instead of multiple individual calls
   const balance1 = await provider.getBalance(address1);
   const balance2 = await provider.getBalance(address2);
   
   // Use batch requests
   const [balance1, balance2] = await Promise.all([
     provider.getBalance(address1),
     provider.getBalance(address2)
   ]);
   ```

## Node Setup and Building Issues

### Go Build Failures

**Symptoms:**
- "go: command not found"
- Compilation errors
- Missing dependencies

**Solutions:**

1. **Verify Go Installation**
   ```bash
   go version
   # Should show Go 1.15 or higher
   
   # If not installed or wrong version:
   # Download from https://golang.org/dl/
   ```

2. **Set Go Environment Variables**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export GOROOT=/usr/local/go
   export GOPATH=$HOME/go
   export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
   
   # Reload shell
   source ~/.bashrc
   ```

3. **Fix Module Dependencies**
   ```bash
   cd Core-Blockchain/node_src
   
   # Clean module cache
   go clean -modcache
   
   # Download dependencies
   go mod download
   go mod tidy
   
   # Build again
   go build -o geth.exe ./cmd/geth
   ```

4. **Windows-Specific Issues**
   ```bash
   # Install TDM-GCC or MinGW-w64
   # Add to PATH: C:\TDM-GCC-64\bin
   
   # Set CGO environment
   set CGO_ENABLED=1
   set CC=gcc
   ```

### Node.js and npm Issues

**Symptoms:**
- "npm: command not found"
- Package installation failures
- Version conflicts

**Solutions:**

1. **Install/Update Node.js**
   ```bash
   # Check current version
   node --version
   npm --version
   
   # Install Node.js 16+ from https://nodejs.org/
   # Or use nvm (recommended)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

2. **Clear npm Cache**
   ```bash
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Fix Permission Issues (Linux/macOS)**
   ```bash
   # Change npm default directory
   mkdir ~/.npm-global
   npm config set prefix '~/.npm-global'
   echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

## MetaMask Integration Issues

### Network Not Appearing

**Symptoms:**
- Splendor network not showing in MetaMask
- "Add Network" button not working
- Wrong chain ID displayed

**Solutions:**

1. **Manual Network Addition**
   - Open MetaMask
   - Click network dropdown
   - Select "Add Network" → "Add a network manually"
   - Enter exact details:
     ```
     Network Name: Splendor RPC
     RPC URL: https://mainnet-rpc.splendor.org/
     Chain ID: 2691
     Currency Symbol: SPLD
     Block Explorer: https://explorer.splendor.org/
     ```

2. **Clear MetaMask Cache**
   - Settings → Advanced → Reset Account
   - **Warning**: This clears transaction history but not funds

3. **Browser Issues**
   ```javascript
   // Test if MetaMask is properly installed
   if (typeof window.ethereum === 'undefined') {
     console.error('MetaMask not installed');
   } else {
     console.log('MetaMask detected');
   }
   ```

### Transaction Failures

**Symptoms:**
- "Transaction failed" errors
- "Insufficient funds" with adequate balance
- Stuck pending transactions

**Solutions:**

1. **Check Gas Settings**
   ```javascript
   // Get current gas price
   const gasPrice = await provider.getFeeData();
   console.log('Gas price:', gasPrice.gasPrice);
   
   // Set appropriate gas limit
   const gasLimit = await contract.estimateGas.methodName();
   const tx = await contract.methodName({ gasLimit: gasLimit.mul(120).div(100) });
   ```

2. **Reset Account Nonce**
   - MetaMask Settings → Advanced → Reset Account
   - This fixes stuck transactions

3. **Increase Gas Price**
   - Use MetaMask's "Fast" or "Fastest" options
   - Or set custom gas price 10-20% higher than suggested

## Validator Node Issues

### Node Won't Start

**Symptoms:**
- "Address already in use" errors
- "Permission denied" errors
- Node crashes immediately

**Solutions:**

1. **Check Port Availability**
   ```bash
   # Check if ports are in use
   netstat -tulpn | grep :8545  # RPC port
   netstat -tulpn | grep :30303 # P2P port
   
   # Kill existing processes
   sudo pkill geth
   
   # Windows
   taskkill /F /IM geth.exe
   ```

2. **Fix Permission Issues**
   ```bash
   # Ensure data directory is writable
   chmod -R 755 ./data
   chown -R $USER:$USER ./data
   
   # Windows: Run as Administrator
   ```

3. **Verify Genesis Initialization**
   ```bash
   # Re-initialize if needed
   rm -rf ./data/geth
   ./geth.exe init genesis.json --datadir ./data
   ```

### Sync Issues

**Symptoms:**
- Node stuck at old block height
- "No suitable peers available"
- Slow synchronization

**Solutions:**

1. **Check Peer Connections**
   ```bash
   # Check peer count
   curl -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8545
   ```

2. **Add Bootstrap Nodes**
   ```bash
   # Add to config.toml
   [Node.P2P]
   BootstrapNodes = [
     "enode://[node1]@ip1:port1",
     "enode://[node2]@ip2:port2"
   ]
   ```

3. **Force Resync**
   ```bash
   # Stop node
   pkill geth
   
   # Remove chain data (keeps keystore)
   rm -rf ./data/geth
   
   # Reinitialize and restart
   ./geth.exe init genesis.json --datadir ./data
   # Start node normally
   ```

### Performance Issues

**Symptoms:**
- High CPU/memory usage
- Slow block processing
- Frequent crashes

**Solutions:**

1. **Optimize Configuration**
   ```toml
   # config.toml optimizations
   [Eth]
   DatabaseCache = 2048
   TrieCleanCache = 512
   TrieDirtyCache = 256
   SnapshotCache = 256
   
   [Node.P2P]
   MaxPeers = 25
   ```

2. **Monitor System Resources**
   ```bash
   # Linux
   htop
   iostat -x 1
   df -h
   
   # Windows
   # Use Task Manager or Resource Monitor
   ```

3. **Increase System Limits**
   ```bash
   # Linux - increase file descriptor limits
   echo "* soft nofile 65536" >> /etc/security/limits.conf
   echo "* hard nofile 65536" >> /etc/security/limits.conf
   ```

## Smart Contract Issues

### Deployment Failures

**Symptoms:**
- "Out of gas" errors
- "Revert" without reason
- Contract not appearing on blockchain

**Solutions:**

1. **Increase Gas Limit**
   ```javascript
   // Hardhat deployment
   const contract = await ContractFactory.deploy({
     gasLimit: 5000000,
     gasPrice: ethers.parseUnits('1', 'gwei')
   });
   ```

2. **Check Contract Size**
   ```bash
   # Compile and check size
   npx hardhat compile
   npx hardhat size-contracts
   
   # If too large, optimize or split contracts
   ```

3. **Verify Network Configuration**
   ```javascript
   // hardhat.config.js
   networks: {
     splendor: {
       url: "https://mainnet-rpc.splendor.org/",
       chainId: 2691,
       accounts: [privateKey],
       gas: 8000000,
       gasPrice: 1000000000
     }
   }
   ```

### Contract Interaction Issues

**Symptoms:**
- Function calls reverting
- Incorrect return values
- Events not emitting

**Solutions:**

1. **Check Function Signatures**
   ```javascript
   // Ensure ABI matches deployed contract
   const contract = new ethers.Contract(address, abi, signer);
   
   // Verify function exists
   console.log(contract.interface.functions);
   ```

2. **Debug Transaction Calls**
   ```javascript
   // Use call() to test without sending transaction
   try {
     const result = await contract.methodName.staticCall();
     console.log('Call result:', result);
   } catch (error) {
     console.error('Call failed:', error.reason);
   }
   ```

3. **Check Event Logs**
   ```javascript
   // Listen for events
   contract.on('EventName', (param1, param2, event) => {
     console.log('Event emitted:', { param1, param2, event });
   });
   
   // Query past events
   const events = await contract.queryFilter('EventName', fromBlock, toBlock);
   ```

## System Contract Issues

### Cannot Access System Contracts

**Symptoms:**
- System contract calls failing
- "Contract not found" errors
- Incorrect contract addresses

**Solutions:**

1. **Verify Contract Addresses**
   ```javascript
   const systemContracts = {
     validators: '0x000000000000000000000000000000000000F000',
     punish: '0x000000000000000000000000000000000000F001',
     proposal: '0x000000000000000000000000000000000000F002',
     slashing: '0x000000000000000000000000000000000000F003',
     params: '0x000000000000000000000000000000000000F004'
   };
   
   // Check if contract exists
   const code = await provider.getCode(systemContracts.validators);
   if (code === '0x') {
     console.error('Contract not deployed');
   }
   ```

2. **Use Correct ABI**
   ```javascript
   // Ensure you're using the correct ABI for system contracts
   // Check the System-Contracts/artifacts directory
   ```

### Validator Registration Issues

**Symptoms:**
- Staking transactions failing
- "Insufficient stake" errors
- Validator not appearing in list

**Solutions:**

1. **Check Minimum Stake Requirements**
   ```javascript
   const minStake = ethers.parseEther('3947'); // Bronze tier
   const userBalance = await provider.getBalance(address);
   
   if (userBalance < minStake) {
     console.error('Insufficient balance for staking');
   }
   ```

2. **Verify Staking Transaction**
   ```javascript
   const tx = await validatorsContract.stake({
     value: ethers.parseEther('3947'),
     gasLimit: 500000
   });
   
   const receipt = await tx.wait();
   console.log('Staking successful:', receipt.hash);
   ```

## Performance and Optimization

### Slow Application Performance

**Symptoms:**
- Long loading times
- Unresponsive UI
- High memory usage

**Solutions:**

1. **Optimize RPC Calls**
   ```javascript
   // Cache frequently accessed data
   const cache = new Map();
   
   async function getCachedBalance(address) {
     if (cache.has(address)) {
       return cache.get(address);
     }
     
     const balance = await provider.getBalance(address);
     cache.set(address, balance);
     setTimeout(() => cache.delete(address), 30000); // 30s cache
     
     return balance;
   }
   ```

2. **Use Efficient Queries**
   ```javascript
   // Instead of querying each block individually
   const blocks = [];
   for (let i = 0; i < 100; i++) {
     blocks.push(await provider.getBlock(i));
   }
   
   // Use batch requests
   const blockPromises = [];
   for (let i = 0; i < 100; i++) {
     blockPromises.push(provider.getBlock(i));
   }
   const blocks = await Promise.all(blockPromises);
   ```

3. **Implement Pagination**
   ```javascript
   // For large datasets, implement pagination
   async function getValidatorsPaginated(page = 0, limit = 50) {
     const validators = await validatorsContract.getValidators();
     const start = page * limit;
     const end = start + limit;
     return validators.slice(start, end);
   }
   ```

## Security Issues

### Private Key Management

**Symptoms:**
- "Invalid private key" errors
- Unauthorized transactions
- Account access issues

**Solutions:**

1. **Secure Key Storage**
   ```javascript
   // Never hardcode private keys
   // Use environment variables
   const privateKey = process.env.PRIVATE_KEY;
   
   // Or use encrypted keystores
   const wallet = await ethers.Wallet.fromEncryptedJson(
     keystoreJson,
     password
   );
   ```

2. **Use Hardware Wallets**
   ```javascript
   // For production, use hardware wallets
   // Ledger, Trezor, etc.
   ```

3. **Implement Multi-signature**
   ```solidity
   // Use multi-sig contracts for important operations
   // Require multiple signatures for critical functions
   ```

### Smart Contract Security

**Symptoms:**
- Unexpected behavior
- Funds locked in contracts
- Reentrancy attacks

**Solutions:**

1. **Use Security Best Practices**
   ```solidity
   // Use OpenZeppelin contracts
   import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
   import "@openzeppelin/contracts/access/Ownable.sol";
   
   contract MyContract is ReentrancyGuard, Ownable {
     // Implementation
   }
   ```

2. **Implement Access Controls**
   ```solidity
   modifier onlyValidator() {
     require(isValidator(msg.sender), "Not a validator");
     _;
   }
   ```

3. **Test Thoroughly**
   ```javascript
   // Write comprehensive tests
   describe("Contract Security", function() {
     it("should prevent reentrancy attacks", async function() {
       // Test implementation
     });
   });
   ```

## Common Error Messages

### "Insufficient funds for gas * price + value"

**Cause:** Not enough SPLD to cover transaction costs
**Solution:**
```javascript
// Check balance before transaction
const balance = await provider.getBalance(address);
const gasEstimate = await contract.estimateGas.methodName();
const gasPrice = await provider.getFeeData();
const totalCost = gasEstimate * gasPrice.gasPrice;

if (balance < totalCost) {
  console.error('Insufficient funds');
}
```

### "Transaction underpriced"

**Cause:** Gas price too low
**Solution:**
```javascript
// Increase gas price
const feeData = await provider.getFeeData();
const tx = await contract.methodName({
  gasPrice: feeData.gasPrice * 110n / 100n // 10% higher
});
```

### "Nonce too low"

**Cause:** Transaction nonce conflict
**Solution:**
```javascript
// Get correct nonce
const nonce = await provider.getTransactionCount(address, 'pending');
const tx = await contract.methodName({ nonce });
```

### "Execution reverted"

**Cause:** Smart contract function failed
**Solution:**
```javascript
// Debug the revert reason
try {
  await contract.methodName();
} catch (error) {
  console.error('Revert reason:', error.reason);
  console.error('Error data:', error.data);
}
```

## Getting Help

### Self-Help Resources

1. **Check Documentation**
   - [Getting Started Guide](GETTING_STARTED.md)
   - [API Reference](API_REFERENCE.md)
   - [Validator Guide](VALIDATOR_GUIDE.md)

2. **Use Debugging Tools**
   ```bash
   # Enable debug logging
   DEBUG=* npm start
   
   # Use browser developer tools
   # Check console for errors
   ```

3. **Test on Testnet First**
   - Always test locally before mainnet
   - Use local development for debugging and testing

### Community Support

1. **Discord/Telegram**
   - Join the official Splendor community
   - Ask questions in developer channels
   - Share solutions with others

2. **GitHub Issues**
   - Report bugs with detailed information
   - Include error messages and steps to reproduce
   - Check existing issues first

3. **Stack Overflow**
   - Tag questions with `splendor-blockchain`
   - Provide minimal reproducible examples
   - Include relevant code and error messages

### Professional Support

For enterprise users or complex issues:

1. **Technical Consulting**
   - Hire blockchain developers
   - Get architecture reviews
   - Custom integration support

2. **Security Audits**
   - Smart contract audits
   - Infrastructure security reviews
   - Penetration testing

## Preventive Measures

### Regular Maintenance

1. **Keep Software Updated**
   ```bash
   # Update Node.js and npm
   npm update -g npm
   
   # Update Go
   # Download latest from golang.org
   
   # Update dependencies
   npm audit fix
   ```

2. **Monitor System Health**
   ```bash
   # Set up monitoring scripts
   # Check disk space, memory, CPU
   # Monitor network connectivity
   ```

3. **Backup Important Data**
   ```bash
   # Backup keystores
   cp -r data/keystore/ backup/
   
   # Backup configuration
   cp config.toml backup/
   ```

### Best Practices

1. **Development**
   - Use version control (Git)
   - Write tests for all code
   - Use linting and formatting tools
   - Document your code

2. **Deployment**
   - Test locally first
   - Use staging environments
   - Implement gradual rollouts
   - Have rollback plans

3. **Operations**
   - Monitor system metrics
   - Set up alerting
   - Regular security updates
   - Disaster recovery plans

---

**Remember**: When in doubt, always test on testnet first and never risk more than you can afford to lose. The blockchain is immutable, so mistakes can be costly.

For urgent issues or security concerns, contact the Splendor team immediately through official channels.
