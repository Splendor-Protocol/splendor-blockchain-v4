const { ethers } = require('ethers');

async function testMainnet() {
    console.log('🚀 Splendor Mainnet Verification Script');
    console.log('====================================\n');

    // Connect to the mainnet
    const provider = new ethers.JsonRpcProvider('https://splendor-rpc.org/');
    
    try {
        // Test 1: Check network connection
        console.log('1. Testing network connection...');
        const network = await provider.getNetwork();
        console.log(`   ✅ Connected to network with Chain ID: ${network.chainId}`);
        
        if (network.chainId !== 2691n) {
            throw new Error(`Expected Chain ID 2691, got ${network.chainId}`);
        }

        // Test 2: Check block number
        console.log('\n2. Checking current block...');
        const blockNumber = await provider.getBlockNumber();
        console.log(`   ✅ Current block number: ${blockNumber}`);

        // Test 3: Check system contracts
        console.log('\n3. Checking system contracts...');
        const systemContracts = [
            { name: 'Validators', address: '0x000000000000000000000000000000000000F000' },
            { name: 'Punish', address: '0x000000000000000000000000000000000000F001' },
            { name: 'Proposal', address: '0x000000000000000000000000000000000000F002' },
            { name: 'Slashing', address: '0x000000000000000000000000000000000000F003' },
            { name: 'Params', address: '0x000000000000000000000000000000000000F004' }
        ];

        for (const contract of systemContracts) {
            const code = await provider.getCode(contract.address);
            if (code === '0x') {
                throw new Error(`${contract.name} contract not deployed at ${contract.address}`);
            }
            console.log(`   ✅ ${contract.name} contract deployed at ${contract.address}`);
        }

        // Test 4: Test RPC methods
        console.log('\n4. Testing RPC methods...');
        const gasPrice = await provider.getFeeData();
        console.log(`   ✅ Gas price: ${gasPrice.gasPrice} wei`);

        const latestBlock = await provider.getBlock('latest');
        console.log(`   ✅ Latest block hash: ${latestBlock.hash}`);

        // Test 5: Check validator count (if accessible)
        console.log('\n5. Checking network status...');
        try {
            const validatorsContract = new ethers.Contract(
                '0x000000000000000000000000000000000000F000',
                ['function getValidators() view returns (address[])'],
                provider
            );
            const validators = await validatorsContract.getValidators();
            console.log(`   ✅ Active validators: ${validators.length}`);
        } catch (error) {
            console.log(`   ⚠️  Could not fetch validator count: ${error.message}`);
        }

        console.log('\n🎉 All tests passed! Splendor Mainnet is working correctly.');
        console.log('\n📋 Mainnet Information:');
        console.log(`   • Network ID: 2691`);
        console.log(`   • Chain ID: 2691`);
        console.log(`   • RPC URL: https://splendor-rpc.org/`);
        console.log(`   • Block Explorer: https://splendor-rpc.org/`);
        console.log(`   • Currency Symbol: SPLD`);
        console.log(`   • Consensus: Congress (Proof of Authority)`);
        console.log(`   • Block Time: ~1 second`);

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('   • Check your internet connection');
        console.log('   • Verify the RPC endpoint is accessible');
        console.log('   • Ensure the mainnet is running');
        console.log('   • Check firewall settings');
        process.exit(1);
    }
}

// Run if this script is executed directly
if (require.main === module) {
    testMainnet().catch(console.error);
}

module.exports = { testMainnet };
