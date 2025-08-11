import fs from 'fs';
import net from 'net';
import axios from 'axios';
import { Web3 } from 'web3';
import { IpcProvider } from 'web3-providers-ipc';

const IPC_PATH = '/root/splendor-blockchain-v4-testnet/Core-Blockchain/chaindata/node1/geth.ipc';
const ACCESS_TOKEN = '123075ee67-27ca-4acf-a61a-459c2a00be08';
const POST_API_URL = 'http://64.227.190.6/post-enode';
const GET_API_URL = 'http://64.227.190.6/get-enode';
const INTERVAL = 5000;

let provider;
let web3;

function sendJsonRpcRequest(method, params = []) {
  return new Promise((resolve, reject) => {
    const client = net.createConnection(IPC_PATH);

    client.on('connect', () => {
      const request = JSON.stringify({
        jsonrpc: '2.0',
        method,
        params,
        id: Date.now(),
      });

      client.write(`${request}\n`);
    });

    client.on('data', (data) => {
      try {
        const response = JSON.parse(data.toString());
        if (response.error) {
          reject(response.error);
        } else {
          resolve(response.result);
        }
      } catch (error) {
        reject(error);
      } finally {
        client.end();
      }
    });

    client.on('error', (error) => {
      reject(error);
    });
  });
}

async function getEnodeAddress() {
  try {
    let nodeInfo = await sendJsonRpcRequest('admin_nodeInfo');
    return nodeInfo.enode;
  } catch (error) {
    console.error('Error fetching enode address:', error);
    throw error;
  }
}

async function postEnodeAddress() {
  try {
    const enode = await getEnodeAddress();
    console.log('Enode Address:', enode);

    if (!ACCESS_TOKEN) {
      throw new Error('ACCESS_TOKEN is not defined');
    }

    const response = await axios.post(POST_API_URL, { enode }, {
      headers: { Authorization: ACCESS_TOKEN }
    });
    console.log('Posted enode address:', response.data);
  } catch (error) {
    console.error('Error posting enode address:', error.response.data);
  }
}

async function addPeers() {
  try {
    if (!ACCESS_TOKEN) {
      throw new Error('ACCESS_TOKEN is not defined');
    }

    const response = await axios.get(GET_API_URL, {
      headers: { Authorization: ACCESS_TOKEN }
    });
    const enodeList = response.data;
    const ownEnode = await getEnodeAddress();

    for (const enode of enodeList) {
      if (enode !== ownEnode) {
        try {
          await sendJsonRpcRequest('admin_addPeer', [enode]);
          console.log('Added peer:', enode);
        } catch (error) {
          console.error('Error adding peer:', error);
        }
      }
    }
  } catch (error) {
    console.error('Error adding peers:', error);
  }
}

function runPeriodically(fn, interval) {
  let isRunning = false;

  const execute = async () => {
    if (isRunning) return;
    isRunning = true;
    try {
      await fn();
    } catch (error) {
      console.error('Error executing function:', error);
    }
    isRunning = false;
  };

  setInterval(execute, interval);
}

function waitForIpcFile() {
  const checkFileExists = () => {
    if (fs.existsSync(IPC_PATH)) {
      console.log('IPC file found. Starting execution...');
      provider = new IpcProvider(IPC_PATH, net);
      web3 = new Web3(provider);
      
      runPeriodically(postEnodeAddress, 15000);
      runPeriodically(addPeers, 9000);
    } else {
      console.log('IPC file not found. Waiting...');
      setTimeout(checkFileExists, INTERVAL);
    }
  };

  checkFileExists();
}

// Start the IPC file check
waitForIpcFile();
