# Splendor Blockchain API Reference

This document provides comprehensive information about the Splendor Blockchain V4 JSON-RPC API, system contracts, and development interfaces.

## Overview

Splendor Blockchain V4 is fully compatible with Ethereum's JSON-RPC API, making it easy to integrate with existing tools and libraries. The mainnet RPC endpoint is available at `https://mainnet-rpc.splendor.org/`.

## Network Information

| Parameter | Value |
|-----------|-------|
| **Network Name** | Splendor RPC |
| **Chain ID** | 2691 |
| **Network ID** | 2691 |
| **Currency Symbol** | SPLD |
| **RPC URL** | https://mainnet-rpc.splendor.org/ |
| **Block Explorer** | https://explorer.splendor.org/ |
| **Block Time** | ~1 second |
| **Consensus** | Congress (PoA) |

## JSON-RPC API

### Standard Ethereum Methods

Splendor supports all standard Ethereum JSON-RPC methods:

#### Network Information

```bash
# Get chain ID
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get network ID
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Block Information

```bash
# Get latest block number
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get block by number
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",true],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get block by hash
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getBlockByHash","params":["0x...","true"],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Account Information

```bash
# Get account balance
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x...","latest"],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get transaction count (nonce)
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0x...","latest"],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Transaction Operations

```bash
# Send raw transaction
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0x..."],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get transaction by hash
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["0x..."],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get transaction receipt
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["0x..."],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Smart Contract Interaction

```bash
# Call contract method (read-only)
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0x...","data":"0x..."},"latest"],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Estimate gas for transaction
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_estimateGas","params":[{"to":"0x...","data":"0x..."}],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get contract code
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0x...","latest"],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Gas and Fee Information

```bash
# Get gas price
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Get fee history
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_feeHistory","params":["0x4","latest",[]],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

### Extended Methods

Splendor also supports additional methods for enhanced functionality:

#### Debug Methods

```bash
# Trace transaction
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"debug_traceTransaction","params":["0x..."],"id":1}' \
     https://mainnet-rpc.splendor.org/

# Trace block
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"debug_traceBlockByNumber","params":["latest"],"id":1}' \
     https://mainnet-rpc.splendor.org/
```

#### Admin Methods

```bash
# Get node info
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
     http://localhost:8545

# Get peers
curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
     http://localhost:8545
```

## System Contracts

Splendor includes several pre-deployed system contracts for network governance and validation:

### Validators Contract (0x000000000000000000000000000000000000F000)

Manages validator registration, staking, and rewards.

#### Key Methods

```solidity
// Get all active validators
function getValidators() external view returns (address[] memory)

// Get validator information
function getValidatorInfo(address validator) external view returns (
    uint256 stake,
    bool isActive,
    uint256 tier,
    uint256 rewards
)

// Stake tokens to become validator
function stake() external payable

// Unstake tokens
function unstake(uint256 amount) external

// Claim rewards
function claimRewards() external
```

#### JavaScript Example

```javascript
const { ethers } = require('ethers');

const provider = new ethers.JsonRpcProvider('https://mainnet-rpc.splendor.org/');
const validatorsContract = new ethers.Contract(
  '0x000000000000000000000000000000000000F000',
  [
    'function getValidators() view returns (address[])',
    'function getValidatorInfo(address) view returns (uint256, bool, uint256, uint256)',
    'function stake() payable',
    'function unstake(uint256) external',
    'function claimRewards() external'
  ],
  provider
);

// Get all validators
const validators = await validatorsContract.getValidators();
console.log('Active validators:', validators);

// Get validator info
const [stake, isActive, tier, rewards] = await validatorsContract.getValidatorInfo('0x...');
console.log('Validator stake:', ethers.formatEther(stake), 'SPLD');
```

### Punish Contract (0x000000000000000000000000000000000000F001)

Handles validator punishment and slashing mechanisms.

#### Key Methods

```solidity
// Check if validator is jailed
function isJailed(address validator) external view returns (bool)

// Get jail information
function getJailInfo(address validator) external view returns (
    bool isJailed,
    uint256 jailTime,
    uint256 releaseTime
)

// Slash validator (internal)
function slash(address validator, uint256 amount) external

// Jail validator (internal)
function jail(address validator, uint256 duration) external
```

### Proposal Contract (0x000000000000000000000000000000000000F002)

Manages validator proposals and governance voting.

#### Key Methods

```solidity
// Create validator proposal
function createProposal(address validator, string memory description) external

// Vote on proposal
function vote(uint256 proposalId, bool support) external

// Execute proposal
function executeProposal(uint256 proposalId) external

// Get proposal information
function getProposal(uint256 proposalId) external view returns (
    address validator,
    string memory description,
    uint256 forVotes,
    uint256 againstVotes,
    bool executed,
    uint256 deadline
)
```

### Slashing Contract (0x000000000000000000000000000000000000F003)

Implements slashing logic for validator misbehavior.

#### Key Methods

```solidity
// Report double signing
function reportDoubleSign(
    address validator,
    bytes memory evidence1,
    bytes memory evidence2
) external

// Get slashing parameters
function getSlashingParams() external view returns (
    uint256 doubleSignSlashAmount,
    uint256 downtimeSlashAmount,
    uint256 jailDuration
)
```

### Params Contract (0x000000000000000000000000000000000000F004)

Stores and manages network parameters.

#### Key Methods

```solidity
// Get network parameters
function getParams() external view returns (
    uint256 blockTime,
    uint256 epochLength,
    uint256 maxValidators,
    uint256 minStake
)

// Get specific parameter
function getParam(string memory key) external view returns (uint256)
```

## Web3 Integration

### Web3.js

```javascript
const Web3 = require('web3');

// Connect to Splendor mainnet
const web3 = new Web3('https://mainnet-rpc.splendor.org/');

// Get network info
const chainId = await web3.eth.getChainId();
console.log('Chain ID:', chainId); // Should be 2691

// Get latest block
const latestBlock = await web3.eth.getBlockNumber();
console.log('Latest block:', latestBlock);

// Get account balance
const balance = await web3.eth.getBalance('0x...');
console.log('Balance:', web3.utils.fromWei(balance, 'ether'), 'SPLD');

// Send transaction
const tx = {
  from: '0x...',
  to: '0x...',
  value: web3.utils.toWei('1', 'ether'),
  gas: 21000
};

const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
```

### Ethers.js

```javascript
const { ethers } = require('ethers');

// Connect to Splendor mainnet
const provider = new ethers.JsonRpcProvider('https://mainnet-rpc.splendor.org/');

// Get network info
const network = await provider.getNetwork();
console.log('Network:', network.name, 'Chain ID:', network.chainId);

// Get latest block
const blockNumber = await provider.getBlockNumber();
console.log('Latest block:', blockNumber);

// Get account balance
const balance = await provider.getBalance('0x...');
console.log('Balance:', ethers.formatEther(balance), 'SPLD');

// Create wallet and send transaction
const wallet = new ethers.Wallet(privateKey, provider);
const tx = await wallet.sendTransaction({
  to: '0x...',
  value: ethers.parseEther('1.0')
});

const receipt = await tx.wait();
console.log('Transaction hash:', receipt.hash);
```

## Rate Limits and Best Practices

### Rate Limits

The public RPC endpoint has the following rate limits:

- **Requests per second**: 100 RPS per IP
- **Requests per minute**: 6,000 RPM per IP
- **Concurrent connections**: 50 per IP

### Best Practices

1. **Connection Pooling**: Reuse connections when possible
2. **Batch Requests**: Use batch RPC calls for multiple operations
3. **Caching**: Cache frequently accessed data
4. **Error Handling**: Implement proper retry logic
5. **Monitoring**: Monitor your API usage and performance

### Batch Requests

```javascript
// Batch multiple requests
const batch = [
  {
    jsonrpc: '2.0',
    method: 'eth_blockNumber',
    params: [],
    id: 1
  },
  {
    jsonrpc: '2.0',
    method: 'eth_gasPrice',
    params: [],
    id: 2
  },
  {
    jsonrpc: '2.0',
    method: 'eth_getBalance',
    params: ['0x...', 'latest'],
    id: 3
  }
];

const response = await fetch('https://mainnet-rpc.splendor.org/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(batch)
});

const results = await response.json();
```

## WebSocket API

For real-time data, use the WebSocket endpoint:

```javascript
const WebSocket = require('ws');

const ws = new WebSocket('wss://mainnet-rpc.splendor.org/ws');

ws.on('open', () => {
  // Subscribe to new blocks
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'eth_subscribe',
    params: ['newHeads'],
    id: 1
  }));
});

ws.on('message', (data) => {
  const message = JSON.parse(data);
  if (message.method === 'eth_subscription') {
    console.log('New block:', message.params.result);
  }
});
```

## Error Codes

Common JSON-RPC error codes:

| Code | Message | Description |
|------|---------|-------------|
| -32700 | Parse error | Invalid JSON |
| -32600 | Invalid Request | Invalid request object |
| -32601 | Method not found | Method doesn't exist |
| -32602 | Invalid params | Invalid method parameters |
| -32603 | Internal error | Internal JSON-RPC error |
| -32000 | Server error | Generic server error |

## SDK and Libraries

### Official Libraries

- **JavaScript/TypeScript**: ethers.js, web3.js
- **Python**: web3.py
- **Go**: go-ethereum client
- **Java**: web3j
- **Rust**: ethers-rs

### Example: Python Integration

```python
from web3 import Web3

# Connect to Splendor mainnet
w3 = Web3(Web3.HTTPProvider('https://mainnet-rpc.splendor.org/'))

# Check connection
print(f"Connected: {w3.isConnected()}")
print(f"Chain ID: {w3.eth.chain_id}")

# Get latest block
latest_block = w3.eth.block_number
print(f"Latest block: {latest_block}")

# Get account balance
balance = w3.eth.get_balance('0x...')
print(f"Balance: {w3.fromWei(balance, 'ether')} SPLD")

# Interact with validators contract
validators_contract = w3.eth.contract(
    address='0x000000000000000000000000000000000000F000',
    abi=[...]  # Contract ABI
)

validators = validators_contract.functions.getValidators().call()
print(f"Active validators: {len(validators)}")
```

## Testing and Development

### Local Development

For local development, you can run a local node:

```bash
# Start local node
cd Core-Blockchain
./geth.exe --datadir ./data --http --http.api "eth,net,web3,personal,admin,debug" --http.corsdomain "*"
```

### Testnet

For testing without real funds, use a local development environment:

- **RPC URL**: `http://localhost:8546` (if running locally)
- **Chain ID**: 2691 (same as mainnet for consistency)
- **Local Development**: Use Hardhat or Ganache for testing

## Security Considerations

### API Security

1. **HTTPS Only**: Always use HTTPS endpoints in production
2. **API Keys**: Use API keys when available
3. **Rate Limiting**: Respect rate limits
4. **Input Validation**: Validate all inputs
5. **Error Handling**: Don't expose sensitive information in errors

### Smart Contract Security

1. **Verify Contracts**: Always verify contract addresses
2. **Test Thoroughly**: Test all interactions locally first
3. **Use Libraries**: Use well-tested libraries like OpenZeppelin
4. **Audit Code**: Get security audits for production contracts

## Support and Resources

### Documentation

- [Getting Started Guide](GETTING_STARTED.md)
- [MetaMask Setup](METAMASK_SETUP.md)
- [Validator Guide](VALIDATOR_GUIDE.md)
- [Smart Contract Development](SMART_CONTRACTS.md)

### Community

- **Discord**: Join our developer community
- **GitHub**: Report issues and contribute
- **Stack Overflow**: Tag questions with `splendor-blockchain`

### Professional Support

For enterprise support and custom integrations, contact the Splendor team through official channels.

---

**Note**: This API reference is for Splendor Blockchain V4 mainnet. Always verify contract addresses and endpoints before using in production applications.
