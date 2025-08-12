# Smart Contract Development on Splendor Blockchain

This guide covers smart contract development, deployment, and interaction on the Splendor Blockchain V4 mainnet.

## Overview

Splendor Blockchain V4 is fully compatible with Ethereum, meaning you can use familiar tools and frameworks like Hardhat, Truffle, and Remix. All Ethereum smart contracts can be deployed on Splendor with minimal or no modifications.

## Development Environment Setup

### Prerequisites

- **Node.js** v16+ and **npm**
- **Hardhat** or **Truffle** (recommended: Hardhat)
- **MetaMask** configured for Splendor mainnet
- **SPLD tokens** for gas fees

### Initialize a New Project

```bash
# Create new directory
mkdir my-splendor-dapp
cd my-splendor-dapp

# Initialize npm project
npm init -y

# Install Hardhat
npm install --save-dev hardhat

# Initialize Hardhat project
npx hardhat init
```

### Install Dependencies

```bash
# Essential dependencies
npm install --save-dev @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts

# Additional useful packages
npm install --save-dev @nomiclabs/hardhat-ethers ethers
npm install --save-dev @typechain/hardhat typechain
npm install --save-dev hardhat-gas-reporter
npm install --save-dev solidity-coverage
```

## Hardhat Configuration

### Basic Configuration

Create or update `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // Splendor Mainnet
    splendor: {
      url: "https://mainnet-rpc.splendor.org/",
      chainId: 2691,
      accounts: [process.env.PRIVATE_KEY], // Add your private key to .env
      gas: 8000000,
      gasPrice: 1000000000 // 1 gwei
    },
    // Local development (if running local node)
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 2691,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },
  etherscan: {
    // Add block explorer API key if available
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

### Environment Variables

Create `.env` file:

```bash
# .env
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_api_key_here
REPORT_GAS=true
```

**Important**: Never commit private keys to version control!

## Writing Smart Contracts

### Basic Contract Structure

```solidity
// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC20, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18; // 1 million tokens
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        require(initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");
        _mint(msg.sender, initialSupply);
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Would exceed max supply");
        _mint(to, amount);
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```

### Advanced Contract Example

```solidity
// contracts/SplendorStaking.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SplendorStaking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    
    uint256 public rewardRate = 100; // 100 tokens per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    
    uint256 private _totalSupply;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored.add(
            block.timestamp.sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }
    
    function earned(address account) public view returns (uint256) {
        return balances[account]
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }
    
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        _totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        
        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }
    
    // Owner functions
    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _rewardRate;
    }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
```

## Testing Smart Contracts

### Basic Test Structure

```javascript
// test/MyToken.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyToken", function () {
  let MyToken;
  let myToken;
  let owner;
  let addr1;
  let addr2;
  
  beforeEach(async function () {
    MyToken = await ethers.getContractFactory("MyToken");
    [owner, addr1, addr2] = await ethers.getSigners();
    
    myToken = await MyToken.deploy(
      "My Token",
      "MTK",
      ethers.parseEther("1000") // 1000 tokens initial supply
    );
  });
  
  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await myToken.owner()).to.equal(owner.address);
    });
    
    it("Should assign the total supply to the owner", async function () {
      const ownerBalance = await myToken.balanceOf(owner.address);
      expect(await myToken.totalSupply()).to.equal(ownerBalance);
    });
    
    it("Should have correct name and symbol", async function () {
      expect(await myToken.name()).to.equal("My Token");
      expect(await myToken.symbol()).to.equal("MTK");
    });
  });
  
  describe("Minting", function () {
    it("Should allow owner to mint tokens", async function () {
      const mintAmount = ethers.parseEther("100");
      await myToken.mint(addr1.address, mintAmount);
      
      expect(await myToken.balanceOf(addr1.address)).to.equal(mintAmount);
    });
    
    it("Should not allow non-owner to mint", async function () {
      const mintAmount = ethers.parseEther("100");
      
      await expect(
        myToken.connect(addr1).mint(addr2.address, mintAmount)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    
    it("Should not allow minting beyond max supply", async function () {
      const maxSupply = await myToken.MAX_SUPPLY();
      const currentSupply = await myToken.totalSupply();
      const excessAmount = maxSupply - currentSupply + ethers.parseEther("1");
      
      await expect(
        myToken.mint(addr1.address, excessAmount)
      ).to.be.revertedWith("Would exceed max supply");
    });
  });
  
  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const transferAmount = ethers.parseEther("50");
      
      await myToken.transfer(addr1.address, transferAmount);
      expect(await myToken.balanceOf(addr1.address)).to.equal(transferAmount);
      
      await myToken.connect(addr1).transfer(addr2.address, transferAmount);
      expect(await myToken.balanceOf(addr2.address)).to.equal(transferAmount);
      expect(await myToken.balanceOf(addr1.address)).to.equal(0);
    });
    
    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await myToken.balanceOf(owner.address);
      const excessAmount = initialOwnerBalance + ethers.parseEther("1");
      
      await expect(
        myToken.connect(addr1).transfer(owner.address, excessAmount)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });
  });
  
  describe("Pausable", function () {
    it("Should pause and unpause transfers", async function () {
      await myToken.pause();
      
      await expect(
        myToken.transfer(addr1.address, ethers.parseEther("10"))
      ).to.be.revertedWith("Pausable: paused");
      
      await myToken.unpause();
      
      await expect(
        myToken.transfer(addr1.address, ethers.parseEther("10"))
      ).to.not.be.reverted;
    });
  });
});
```

### Advanced Testing with Coverage

```bash
# Run tests
npx hardhat test

# Run tests with gas reporting
REPORT_GAS=true npx hardhat test

# Run coverage
npx hardhat coverage

# Run specific test file
npx hardhat test test/MyToken.test.js
```

## Deployment

### Deployment Script

```javascript
// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying contracts to Splendor mainnet...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  
  // Check balance
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "SPLD");
  
  // Deploy MyToken
  const MyToken = await ethers.getContractFactory("MyToken");
  const myToken = await MyToken.deploy(
    "Splendor Token",
    "SPLD",
    ethers.parseEther("1000000") // 1 million initial supply
  );
  
  await myToken.waitForDeployment();
  console.log("MyToken deployed to:", await myToken.getAddress());
  
  // Deploy SplendorStaking
  const SplendorStaking = await ethers.getContractFactory("SplendorStaking");
  const staking = await SplendorStaking.deploy(
    await myToken.getAddress(), // staking token
    await myToken.getAddress()  // reward token (same for simplicity)
  );
  
  await staking.waitForDeployment();
  console.log("SplendorStaking deployed to:", await staking.getAddress());
  
  // Verify deployment
  console.log("\nVerifying deployment...");
  const tokenName = await myToken.name();
  const tokenSymbol = await myToken.symbol();
  const totalSupply = await myToken.totalSupply();
  
  console.log("Token Name:", tokenName);
  console.log("Token Symbol:", tokenSymbol);
  console.log("Total Supply:", ethers.formatEther(totalSupply));
  
  // Save deployment info
  const deploymentInfo = {
    network: "splendor",
    chainId: 2691,
    contracts: {
      MyToken: {
        address: await myToken.getAddress(),
        name: tokenName,
        symbol: tokenSymbol,
        totalSupply: totalSupply.toString()
      },
      SplendorStaking: {
        address: await staking.getAddress(),
        stakingToken: await myToken.getAddress(),
        rewardToken: await myToken.getAddress()
      }
    },
    deployer: deployer.address,
    timestamp: new Date().toISOString()
  };
  
  console.log("\nDeployment completed successfully!");
  console.log("Deployment info:", JSON.stringify(deploymentInfo, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Deploy to Mainnet

```bash
# Deploy to Splendor mainnet
npx hardhat run scripts/deploy.js --network splendor

# Verify contracts (if block explorer supports it)
npx hardhat verify --network splendor CONTRACT_ADDRESS "Constructor" "Arguments"
```

## Interacting with Deployed Contracts

### Using Hardhat Console

```bash
# Open Hardhat console connected to Splendor
npx hardhat console --network splendor
```

```javascript
// In Hardhat console
const MyToken = await ethers.getContractFactory("MyToken");
const myToken = MyToken.attach("0xYourContractAddress");

// Check token details
const name = await myToken.name();
const symbol = await myToken.symbol();
const totalSupply = await myToken.totalSupply();

console.log(`${name} (${symbol}): ${ethers.formatEther(totalSupply)} tokens`);

// Mint tokens
const [owner] = await ethers.getSigners();
await myToken.mint(owner.address, ethers.parseEther("1000"));
```

### Frontend Integration

```javascript
// frontend/src/contracts.js
import { ethers } from 'ethers';

// Contract addresses (update with your deployed addresses)
const CONTRACT_ADDRESSES = {
  MyToken: '0xYourTokenAddress',
  SplendorStaking: '0xYourStakingAddress'
};

// Contract ABIs (import from artifacts)
import MyTokenABI from '../artifacts/contracts/MyToken.sol/MyToken.json';
import StakingABI from '../artifacts/contracts/SplendorStaking.sol/SplendorStaking.json';

export class ContractService {
  constructor() {
    this.provider = null;
    this.signer = null;
    this.contracts = {};
  }
  
  async connect() {
    if (typeof window.ethereum !== 'undefined') {
      this.provider = new ethers.BrowserProvider(window.ethereum);
      await this.provider.send("eth_requestAccounts", []);
      this.signer = await this.provider.getSigner();
      
      // Initialize contracts
      this.contracts.myToken = new ethers.Contract(
        CONTRACT_ADDRESSES.MyToken,
        MyTokenABI.abi,
        this.signer
      );
      
      this.contracts.staking = new ethers.Contract(
        CONTRACT_ADDRESSES.SplendorStaking,
        StakingABI.abi,
        this.signer
      );
      
      return true;
    }
    return false;
  }
  
  async getTokenBalance(address) {
    return await this.contracts.myToken.balanceOf(address);
  }
  
  async stakeTokens(amount) {
    // First approve the staking contract
    const approveTx = await this.contracts.myToken.approve(
      CONTRACT_ADDRESSES.SplendorStaking,
      amount
    );
    await approveTx.wait();
    
    // Then stake
    const stakeTx = await this.contracts.staking.stake(amount);
    return await stakeTx.wait();
  }
  
  async getStakingInfo(address) {
    const [balance, earned] = await Promise.all([
      this.contracts.staking.balanceOf(address),
      this.contracts.staking.earned(address)
    ]);
    
    return { balance, earned };
  }
}
```

### React Component Example

```jsx
// frontend/src/components/TokenStaking.jsx
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { ContractService } from '../contracts';

const TokenStaking = () => {
  const [contractService, setContractService] = useState(null);
  const [account, setAccount] = useState('');
  const [tokenBalance, setTokenBalance] = useState('0');
  const [stakedBalance, setStakedBalance] = useState('0');
  const [earnedRewards, setEarnedRewards] = useState('0');
  const [stakeAmount, setStakeAmount] = useState('');
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    initializeContract();
  }, []);
  
  const initializeContract = async () => {
    const service = new ContractService();
    const connected = await service.connect();
    
    if (connected) {
      setContractService(service);
      const address = await service.signer.getAddress();
      setAccount(address);
      await updateBalances(service, address);
    }
  };
  
  const updateBalances = async (service, address) => {
    try {
      const [tokenBal, stakingInfo] = await Promise.all([
        service.getTokenBalance(address),
        service.getStakingInfo(address)
      ]);
      
      setTokenBalance(ethers.formatEther(tokenBal));
      setStakedBalance(ethers.formatEther(stakingInfo.balance));
      setEarnedRewards(ethers.formatEther(stakingInfo.earned));
    } catch (error) {
      console.error('Error updating balances:', error);
    }
  };
  
  const handleStake = async () => {
    if (!contractService || !stakeAmount) return;
    
    setLoading(true);
    try {
      const amount = ethers.parseEther(stakeAmount);
      await contractService.stakeTokens(amount);
      
      // Update balances
      await updateBalances(contractService, account);
      setStakeAmount('');
    } catch (error) {
      console.error('Staking failed:', error);
      alert('Staking failed: ' + error.message);
    }
    setLoading(false);
  };
  
  const handleClaimRewards = async () => {
    if (!contractService) return;
    
    setLoading(true);
    try {
      const tx = await contractService.contracts.staking.getReward();
      await tx.wait();
      
      // Update balances
      await updateBalances(contractService, account);
    } catch (error) {
      console.error('Claim failed:', error);
      alert('Claim failed: ' + error.message);
    }
    setLoading(false);
  };
  
  if (!contractService) {
    return (
      <div className="container">
        <h2>Token Staking</h2>
        <p>Please connect your wallet to continue.</p>
        <button onClick={initializeContract}>Connect Wallet</button>
      </div>
    );
  }
  
  return (
    <div className="container">
      <h2>Token Staking</h2>
      <p>Account: {account}</p>
      
      <div className="balances">
        <div>Token Balance: {tokenBalance} SPLD</div>
        <div>Staked Balance: {stakedBalance} SPLD</div>
        <div>Earned Rewards: {earnedRewards} SPLD</div>
      </div>
      
      <div className="staking-form">
        <h3>Stake Tokens</h3>
        <input
          type="number"
          placeholder="Amount to stake"
          value={stakeAmount}
          onChange={(e) => setStakeAmount(e.target.value)}
          disabled={loading}
        />
        <button onClick={handleStake} disabled={loading || !stakeAmount}>
          {loading ? 'Staking...' : 'Stake'}
        </button>
      </div>
      
      <div className="rewards-section">
        <h3>Rewards</h3>
        <button onClick={handleClaimRewards} disabled={loading || earnedRewards === '0'}>
          {loading ? 'Claiming...' : 'Claim Rewards'}
        </button>
      </div>
    </div>
  );
};

export default TokenStaking;
```

## Best Practices

### Security Best Practices

1. **Use OpenZeppelin Contracts**
   ```solidity
   import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
   import "@openzeppelin/contracts/access/Ownable.sol";
   import "@openzeppelin/contracts/security/Pausable.sol";
   ```

2. **Implement Access Controls**
   ```solidity
   modifier onlyAuthorized() {
     require(hasRole(AUTHORIZED_ROLE, msg.sender), "Not authorized");
     _;
   }
   ```

3. **Use SafeMath for Older Solidity Versions**
   ```solidity
   // For Solidity < 0.8.0
   using SafeMath for uint256;
   ```

4. **Validate Inputs**
   ```solidity
   function transfer(address to, uint256 amount) public {
     require(to != address(0), "Transfer to zero address");
     require(amount > 0, "Amount must be positive");
     // ... rest of function
   }
   ```

### Gas Optimization

1. **Use `uint256` Instead of Smaller Types**
   ```solidity
   // More gas efficient
   uint256 public value;
   
   // Less efficient (unless packed)
   uint8 public smallValue;
   ```

2. **Pack Struct Variables**
   ```solidity
   struct User {
     uint128 balance;    // 16 bytes
     uint128 timestamp;  // 16 bytes - fits in same slot
     address addr;       // 20 bytes - new slot
     bool active;        // 1 byte - same slot as addr
   }
   ```

3. **Use Events for Data Storage**
   ```solidity
   // Instead of storing in state (expensive)
   mapping(address => uint256[]) public userTransactions;
   
   // Use events (cheaper)
   event Transaction(address indexed user, uint256 amount, uint256 timestamp);
   ```

### Testing Best Practices

1. **Test Edge Cases**
   ```javascript
   it("Should handle zero amounts", async function () {
     await expect(contract.transfer(addr1.address, 0))
       .to.be.revertedWith("Amount must be positive");
   });
   ```

2. **Test Access Controls**
   ```javascript
   it("Should only allow owner to mint", async function () {
     await expect(contract.connect(addr1).mint(addr2.address, 100))
       .to.be.revertedWith("Ownable: caller is not the owner");
   });
   ```

3. **Test State Changes**
   ```javascript
   it("Should update balances correctly", async function () {
     const initialBalance = await contract.balanceOf(owner.address);
     await contract.transfer(addr1.address, 100);
     
     expect(await contract.balanceOf(owner.address))
       .to.equal(initialBalance.sub(100));
     expect(await contract.balanceOf(addr1.address))
       .to.equal(100);
   });
   ```

## Troubleshooting

### Common Issues

1. **"Insufficient funds for gas"**
   - Ensure you have enough SPLD for gas fees
   - Check gas price and limit settings

2. **"Contract creation code storage out of gas"**
   - Contract too large, optimize or split into multiple contracts
   - Increase gas limit

3. **"Transaction underpriced"**
   - Increase gas price in hardhat.config.js

4. **"Nonce too high"**
   - Reset MetaMask account or manage nonces manually

### Debugging Tips

1. **Use Hardhat's `console.log`**
   ```solidity
   import "hardhat/console.sol";
   
   function myFunction() public {
     console.log("Debug value:", someVariable);
   }
   ```

2. **Use Hardhat Network's Tracing**
   ```bash
   npx hardhat test --verbose
   ```

3. **Check Transaction Receipts**
   ```javascript
   const tx = await contract.myFunction();
   const receipt = await tx.wait();
   console.log("Gas used:", receipt.gasUsed.toString());
   console.log("Status:", receipt.status);
   ```

## Resources and References

### Documentation Links

- [Getting Started Guide](GETTING_STARTED.md)
- [MetaMask Setup](METAMASK_SETUP.md)
- [API Reference](API_REFERENCE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

### External Resources

- [Hardhat Documentation](https://hardhat.org/docs/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Ethers.js Documentation](https://docs.ethers.io/)

### Community and Support

- **Discord**: Join the Splendor developer community
- **GitHub**: Report issues and contribute to the ecosystem
- **Stack Overflow**: Tag questions with `splendor-blockchain`

---

**Remember**: Always test your contracts thoroughly in a local development environment before deploying to mainnet. Smart contract bugs can result in permanent loss of funds.

For complex projects, consider getting a professional security audit before mainnet deployment.
