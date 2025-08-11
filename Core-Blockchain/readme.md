
# Splendor RPC Blockchain Node

This project aims to provide installation, running, and maintenance capabilities of **Splendor RPC validator node** for potential and existing Splendor RPC Blockchain backers. The consensus structure of this chain is delegated proof of stake "DPos" and is governed by the symbiosis of Splendor RPC's implementation of go-ethereum and our system contracts. This repository has multiple release candidates inline so we recommend checking for updates for better functions and stability.

## System Requirements

### Validator Nodes
**Operating System:** Ubuntu >= 20.04 LTS

**CPU:** 4 cores minimum (Intel/AMD x64)

**RAM:** 8GB minimum

**Persistent Storage:** 100GB high-speed SSD

**Network:** Stable internet connection with low latency

### RPC Nodes  
**Operating System:** Ubuntu >= 20.04 LTS

**CPU:** 8 cores minimum (Intel/AMD x64)

**RAM:** 16GB minimum

**Persistent Storage:** 200GB high-speed SSD

**Network:** High-bandwidth internet connection for serving requests



## Validator Tiers

Splendor RPC implements a tiered validator system with three levels based on staking amounts:

### **Bronze Tier** - Entry Level
- **Minimum Stake:** 3,947 SPLD (~$1,500)
- **Target Audience:** New validators and smaller participants
- **Benefits:** Basic validator rewards and network participation

### **Silver Tier** - Mid Level  
- **Minimum Stake:** 39,474 SPLD (~$15,000)
- **Target Audience:** Committed validators with higher investment
- **Benefits:** Enhanced network influence and rewards

### **Gold Tier** - Premium Level
- **Minimum Stake:** 394,737 SPLD (~$150,000)
- **Target Audience:** Major validators and institutional participants
- **Benefits:** Maximum network influence and premium rewards

**Note:** Validator tiers are automatically assigned and updated based on total staking amount (including delegated stakes). Higher tiers demonstrate greater commitment to the network.

## Fee Distribution

Splendor RPC uses a fair fee distribution model:

- **60%** to Validators (they invest in and run infrastructure)
- **30%** to Stakers (passive participation through delegation)
- **10%** to Protocol Development (ongoing blockchain improvements)

## How to become a validator
To back the Splendor RPC blockchain you can become a validator. Full flow to become a validator, you must:
* Install this package **([See Installation](#installation))**
* Download your newly created validator wallet from your server and import it into your metamask or preferred wallet. Fund this account with the appropriate SPLD tokens needed to become a validator (minimum 3,947 SPLD for Bronze tier). Example command to download the wallet on your local PC. Only works for UNIX-based OSes or on any environment that can run the OpenSSH package:
```bash
  scp -r root@<server_ip>:/root/splendor-blockchain-v4/Core-Blockchain/chaindata/node1/keystore
  scp root@<server_ip>:/root/splendor-blockchain-v4/Core-Blockchain/chaindata/node1/pass.txt
```
* On your server, start the node that you just installed **([See Usage/Example](#usageexamples))**
* Once the node is started and confirmation is seen on your terminal, open the interactive console by attaching tmux session **([See Usage/Example](#usageexamples))**
* Once inside the interactive console, you'll see "IMPORTED TRANSACTION OBJECTS" and "age=<some period like 6d5hr or 5mon 3weeks>". You need to wait until the "unauthorized validator" warning starts to pop up on the console. 
* Once "unauthorized validators" warning shows up, go to https://dashboard.splendor.org/ and click "Become a Guardian". Fill in your validator name (moniker) and fee address field with the validator wallet address that you imported into your metamask. Proceed further
* Once the last step is done, you'll see a "🔨 mined potential block" message on the interactive console. You'll also see your validator wallet as a validator on the staking page and on explorer. You should also detach from the console after the whole process is done **([See Usage/Example](#usageexamples))**
## Installation

**You must ensure that:** 
* system requirements are met with careful supervision
* the concerned server/local setup must be running 24/7 
* there is sufficient power and cooling arrangement for your machine if running a local setup 
If failed you may end up losing your stake in the blockchain and your staked coins, if any. You'll be jailed at once with no return point by the blockchain if found down/dead. You'll be responsible for chain data corruption on your node, frying up your motherboard, or damaging yourself and your surroundings. 


To install the Splendor RPC validator node in ubuntu linux
```bash
  sudo -i
  apt update && apt upgrade
  apt install git tar curl wget
  reboot
```
Skip the above commands if you have already updated the system and installed the necessary tools.

Connect again to your server after reboot
```bash
  sudo -i
  git clone https://github.com/Splendor-Protocol/splendor-blockchain-v4.git
  cd splendor-blockchain-v4/Core-Blockchain
  ./node-setup.sh --validator 1
```
After you run node-setup, follow the on-screen instructions carefully and you'll get confirmation that the node was successfully installed on your system.

**Note regarding your validator account -** While in the setup process, you'll be asked to create a new account that must be used for block mining and receiving gas rewards. You must import this account to your metamask or any preferred wallet and fund it with the minimum required SPLD tokens for your chosen validator tier.
 
    
## Usage/Examples

Display help
```bash
./node-setup.sh --help
```
To create/install a validator node. Fresh first-time install
```bash
./node-setup.sh --validator 1
```
To run the validator node
```bash
./node-start.sh --validator
```
To create/install a RPC node. Fresh first-time install
```bash
./node-setup.sh --rpc
```
To run the RPC node
```bash
./node-start.sh --rpc
```
To get into a running node's interactive console/tmux session 
```bash
tmux attach -t node1
```
To exit/detach from an interactive console
```text
Press CTRL & b , release both keys, and press d
```
