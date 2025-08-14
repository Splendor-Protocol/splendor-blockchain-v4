# MetaMask Setup for Splendor Mainnet

This guide will help you connect MetaMask to the Splendor Blockchain V4 mainnet for real transactions and DApp interactions.

## Prerequisites

- MetaMask browser extension installed ([Download here](https://metamask.io/))
- SPLD tokens (can be purchased from supported exchanges)

## Adding Splendor Mainnet to MetaMask

### Method 1: Manual Configuration

1. **Open MetaMask** and click on the network dropdown (usually shows "Ethereum Mainnet")

2. **Click "Add Network"** at the bottom of the dropdown

3. **Select "Add a network manually"**

4. **Enter the following details:**

   | Field | Value |
   |-------|-------|
   | **Network Name** | Splendor RPC |
   | **New RPC URL** | https://mainnet-rpc.splendor.org/ |
   | **Chain ID** | 2691 |
   | **Currency Symbol** | SPLD |
   | **Block Explorer URL** | https://explorer.splendor.org/ |

5. **Click "Save"**

6. **Switch to the network** by selecting "Splendor RPC" from the network dropdown

### Method 2: One-Click Add (For DApps)

If you're a developer building a DApp, you can use this JavaScript code to help users add the network:

```javascript
async function addSplendorMainnet() {
  try {
    await window.ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [{
        chainId: '0xA83', // 2691 in hex
        chainName: 'Splendor RPC',
        nativeCurrency: {
          name: 'Splendor',
          symbol: 'SPLD',
          decimals: 18
        },
        rpcUrls: ['https://mainnet-rpc.splendor.org/'],
        blockExplorerUrls: ['https://explorer.splendor.org/']
      }]
    });
    console.log('Splendor Mainnet added successfully!');
  } catch (error) {
    console.error('Failed to add network:', error);
  }
}
```

## Getting SPLD Tokens

### Option 1: Purchase from Exchanges

SPLD tokens can be purchased from supported cryptocurrency exchanges:

- Check [CoinMarketCap](https://coinmarketcap.com/) or [CoinGecko](https://coingecko.com/) for current exchange listings
- Always verify the contract address: `0x...` (to be updated when available)
- Use reputable exchanges with good security practices

### Option 2: Bridge from Other Networks

If bridging is available:

1. **Use Official Bridge**: Only use the official Splendor bridge
2. **Verify Addresses**: Double-check all contract addresses
3. **Start Small**: Test with small amounts first
4. **Allow Time**: Bridge transactions may take time to complete

### Option 3: Receive from Others

- **Wallet Address**: Share your MetaMask address to receive SPLD
- **Verify Network**: Ensure sender is using Splendor mainnet (Chain ID 2691)
- **Check Balance**: Tokens should appear in your MetaMask wallet

## Verifying the Connection

1. **Check Network Status:**
   - MetaMask should show "Splendor RPC" in the network dropdown
   - Your SPLD balance should be displayed

2. **Test Connection:**
   ```javascript
   // In browser console (with MetaMask connected)
   ethereum.request({
     method: 'eth_chainId'
   }).then(chainId => {
     console.log('Connected to chain:', parseInt(chainId, 16)); // Should be 2691
   });
   ```

3. **Check Block Number:**
   ```javascript
   ethereum.request({
     method: 'eth_blockNumber'
   }).then(blockNumber => {
     console.log('Current block:', parseInt(blockNumber, 16));
   });
   ```

## Using MetaMask with Splendor DApps

### Connecting to DApps

1. **Visit a Splendor-compatible DApp**
2. **Click "Connect Wallet"**
3. **Select MetaMask**
4. **Approve the connection**
5. **Ensure you're on Splendor mainnet**

### Making Transactions

1. **Initiate Transaction**: Click send/swap/interact in the DApp
2. **Review Details**: Check recipient, amount, and gas fees
3. **Confirm in MetaMask**: Click "Confirm" to sign the transaction
4. **Wait for Confirmation**: Transactions typically confirm in ~1 second

### Example DApp Integration

```javascript
// Check if MetaMask is installed
if (typeof window.ethereum !== 'undefined') {
  // Request account access
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  
  // Create ethers provider
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  
  // Get user address
  const address = await signer.getAddress();
  console.log('Connected address:', address);
  
  // Check network
  const network = await provider.getNetwork();
  if (network.chainId !== 2691) {
    alert('Please switch to Splendor Mainnet');
  }
}
```

## Common Issues and Solutions

### Network Not Appearing

- **Solution**: Refresh MetaMask or restart your browser
- **Check**: Ensure you entered the correct RPC URL
- **Verify**: Test the RPC endpoint: `https://mainnet-rpc.splendor.org/`

### Connection Refused

- **Solution**: Check your internet connection
- **RPC Issues**: Try refreshing or switching networks
- **Firewall**: Ensure HTTPS connections are allowed

### Transactions Failing

- **Gas Issues**: Ensure you have enough SPLD for gas fees
- **Nonce Issues**: Reset your account in MetaMask (Settings > Advanced > Reset Account)
- **Network Congestion**: Wait and try again during lower traffic periods

### Wrong Balance Displayed

- **Token Import**: You may need to manually add SPLD token
- **Network Switch**: Ensure you're on the correct network
- **Refresh**: Try refreshing MetaMask or the page

### MetaMask Shows Wrong Chain ID

- **Solution**: Remove and re-add the network
- **Clear Cache**: Clear browser cache and MetaMask data
- **Restart**: Restart your browser completely

## Security Best Practices

### Wallet Security

- **Seed Phrase**: Never share your 12/24-word seed phrase
- **Private Keys**: Keep private keys secure and offline
- **Hardware Wallets**: Consider using hardware wallets for large amounts
- **Regular Backups**: Backup your wallet regularly

### Transaction Security

- **Verify Addresses**: Always double-check recipient addresses
- **Check Amounts**: Verify transaction amounts before confirming
- **Gas Fees**: Understand gas fees before confirming
- **Phishing**: Only use official websites and DApps

### Network Security

- **Official RPC**: Only use the official RPC endpoint
- **HTTPS**: Ensure you're using secure connections
- **Bookmarks**: Bookmark official sites to avoid phishing
- **Updates**: Keep MetaMask updated to the latest version

## Advanced Features

### Custom Gas Settings

1. **Open MetaMask Settings**
2. **Go to Advanced**
3. **Enable "Advanced gas controls"**
4. **Set custom gas price and limit**

### Multiple Accounts

1. **Click Account Icon** (top right in MetaMask)
2. **Select "Create Account"**
3. **Name your account**
4. **Switch between accounts as needed**

### Hardware Wallet Integration

1. **Connect Hardware Wallet** (Ledger/Trezor)
2. **Select "Connect Hardware Wallet"**
3. **Follow device instructions**
4. **Import accounts**

## Troubleshooting Checklist

- [ ] MetaMask is installed and updated
- [ ] Network details are entered correctly
- [ ] RPC endpoint is accessible
- [ ] You have SPLD tokens for gas fees
- [ ] You're on the correct network (Chain ID 2691)
- [ ] Browser allows HTTPS connections
- [ ] No firewall blocking connections

## Next Steps

- [Smart Contract Development Guide](SMART_CONTRACTS.md)
- [Validator Guide](VALIDATOR_GUIDE.md)
- [RPC Setup Guide](RPC_SETUP_GUIDE.md)
- [API Reference](API_REFERENCE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## Need Help?

If you encounter issues:
1. Check this troubleshooting section
2. Review the [main documentation](../README.md)
3. Join our community Discord
4. Create an issue in the repository

## Important Disclaimers

- **Mainnet Transactions**: All transactions on mainnet use real SPLD tokens
- **Gas Fees**: All transactions require SPLD for gas fees
- **Irreversible**: Blockchain transactions cannot be reversed
- **Security**: You are responsible for your wallet security
- **Due Diligence**: Always verify contract addresses and DApp authenticity
