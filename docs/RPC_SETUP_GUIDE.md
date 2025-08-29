# RPC Node Setup Guide

This guide explains how to set up additional RPC endpoints for the Splendor Blockchain network.

## Overview

RPC (Remote Procedure Call) nodes provide read-only access to the blockchain network. They allow applications, wallets, and users to interact with the blockchain without participating in consensus. Adding multiple RPC endpoints improves network accessibility, load distribution, and redundancy.

## Prerequisites

- Ubuntu 20.04 LTS (Focal Fossa) or compatible
- Root access to the server
- Minimum 4GB RAM, 2 CPU cores
- Recomended: 16GB RAM and 8 CPU Cores
- At least 100GB available storage
- Recomended: 1TB ssd storage
- Stable internet connection
- Open ports: 80 (HTTP RPC), 8545 (WebSocket), 30303 (P2P)

## Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Splendor-Protocol/splendor-blockchain-v4.git
cd splendor-blockchain-v4/Core-Blockchain
```

### 2. Run RPC Setup

```bash
./node-setup.sh --rpc
```

This will:
- Install all dependencies (Go, Node.js, build tools)
- Build the blockchain node software
- Create RPC node directory structure
- Initialize with genesis block
- Configure automatic startup

### 3. Start the RPC Node

```bash
./node-start.sh --rpc
```

## Manual Setup (Advanced)

If you need to manually create additional RPC nodes:

### 1. Create Node Directory

```bash
# Find next available node number
ls -la ./chaindata/

# Create new node directory (replace X with next number)
mkdir ./chaindata/nodeX
```

### 2. Initialize with Genesis

```bash
./node_src/build/bin/geth --datadir ./chaindata/nodeX init ./genesis.json
```

### 3. Mark as RPC Node

```bash
touch ./chaindata/nodeX/.rpc
```

### 4. Start the Node

```bash
./node-start.sh --rpc
```

## RPC Configuration

Each RPC node runs with the following configuration:

### Network Settings
- **Chain ID**: 2691
- **Network ID**: 2691
- **P2P Port**: 30303
- **Bootnode**: Automatic discovery via working RPC server

### RPC Endpoints
- **HTTP RPC**: Port 80
  - URL: `http://YOUR_SERVER_IP:80`
  - CORS: Enabled for all origins
- **WebSocket**: Port 8545
  - URL: `ws://YOUR_SERVER_IP:8545`
  - Origins: All allowed

### Available APIs
- `db` - Database operations
- `eth` - Ethereum-compatible API
- `net` - Network information
- `web3` - Web3 utilities
- `personal` - Account management
- `txpool` - Transaction pool
- `miner` - Mining information
- `debug` - Debug utilities

### Sync Settings
- **Sync Mode**: Full (complete blockchain history)
- **GC Mode**: Archive (keeps all state)
- **VM Debug**: Enabled
- **Profiling**: Available on port 6060

## Usage Examples

### Web3.js Connection

```javascript
const Web3 = require('web3');
const web3 = new Web3('http://YOUR_RPC_SERVER:80');

// Get latest block
const block = await web3.eth.getBlock('latest');
console.log('Latest block:', block.number);
```

### MetaMask Configuration

1. Open MetaMask
2. Go to Settings → Networks → Add Network
3. Enter:
   - **Network Name**: Splendor Blockchain
   - **RPC URL**: `http://YOUR_RPC_SERVER:80`
   - **Chain ID**: 2691
   - **Currency Symbol**: SPLD
   - **Block Explorer**: (Optional)

### cURL Examples

```bash
# Get latest block number
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://YOUR_RPC_SERVER:80

# Get balance
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xYOUR_ADDRESS","latest"],"id":1}' \
  http://YOUR_RPC_SERVER:80
```

## Monitoring and Management

### Check Node Status

```bash
# List active nodes
tmux ls

# Attach to RPC node console
tmux attach -t nodeX  # Replace X with node number

# Check sync status (in geth console)
> eth.syncing
> net.peerCount
> eth.blockNumber
```

### Log Monitoring

```bash
# View sync-helper logs
pm2 logs

# Check for peer connections
grep "Looking for peers" /path/to/geth/logs
```

### Performance Monitoring

```bash
# Check system resources
htop

# Monitor disk usage
df -h

# Network connections
netstat -tulpn | grep :80
netstat -tulpn | grep :8545
```

## Load Balancing

For high-availability setups, consider using a load balancer:

### Nginx Configuration

```nginx
upstream rpc_backend {
    server rpc1.yourdomain.com:80;
    server rpc2.yourdomain.com:80;
    server rpc3.yourdomain.com:80;
}

server {
    listen 80;
    server_name rpc.yourdomain.com;
    
    location / {
        proxy_pass http://rpc_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Security Considerations

### Firewall Configuration

```bash
# Allow RPC ports
ufw allow 80/tcp
ufw allow 8545/tcp
ufw allow 30303/tcp
ufw allow 30303/udp

# Enable firewall
ufw enable
```

### Rate Limiting

Consider implementing rate limiting to prevent abuse:

```nginx
http {
    limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;
    
    server {
        location / {
            limit_req zone=rpc burst=20 nodelay;
            proxy_pass http://localhost:80;
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Node won't sync**
   - Check bootnode connectivity
   - Verify firewall settings
   - Ensure sufficient disk space

2. **RPC not responding**
   - Check if geth process is running
   - Verify port bindings
   - Check for resource constraints

3. **Peer connection issues**
   - Verify P2P port (30303) is open
   - Check sync-helper is running
   - Confirm bootnode is reachable

### Diagnostic Commands

```bash
# Check geth process
ps aux | grep geth

# Test RPC connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
  http://localhost:80

# Check sync-helper status
pm2 status
```

## Maintenance

### Regular Tasks

1. **Monitor disk usage** - Archive mode requires significant storage
2. **Check sync status** - Ensure node stays synchronized
3. **Update software** - Keep geth binary updated
4. **Backup configuration** - Save node keys and configuration

### Updates

```bash
# Update to latest version
git pull origin main
cd node_src
make geth

# Restart with new binary
./node-stop.sh
./node-start.sh --rpc
```

## Network Impact

Adding RPC nodes provides several benefits:

- **Improved Performance**: Distributes load across multiple endpoints
- **Higher Availability**: Redundancy if one RPC goes offline
- **Geographic Distribution**: Reduced latency for global users
- **Scalability**: Handle more concurrent requests

**Important**: RPC nodes do NOT affect consensus or validator operations. They are read-only participants that enhance network accessibility without impacting blockchain security or performance.

## Support

For additional help:
- Check the main [README.md](../README.md)
- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Consult [VALIDATOR_GUIDE.md](VALIDATOR_GUIDE.md) for validator-specific information

---

**Note**: This guide assumes you have a working Splendor Blockchain network. RPC nodes connect to existing validators and do not participate in block production or consensus.
