# PM2 Startup Error Fix Guide

## What This Fixes
- ❌ `[PM2][ERROR] Script already launched, add -f option to force re-execution`
- ❌ `pm2: command not found`

## Quick Fix for Existing Validators

### Step 1: Check if you need NVM/PM2
```bash
# Test if PM2 is available
pm2 --version
```

**If you get "command not found", install NVM first:**
```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Install Node.js and PM2
nvm install node
npm install -g pm2
```

### Step 2: Fix the startup script
**Choose ONE option:**

**Option A - Copy the fixed file (Easiest):**
```bash
# From your local machine
scp Core-Blockchain/node-start.sh YOUR_USER@YOUR_SERVER_IP:~/splendor-blockchain-v4/Core-Blockchain/
```

**Option B - Use the fix script:**
```bash
# Download and run the fix script
wget https://raw.githubusercontent.com/Splendor-Protocol/splendor-blockchain-v4/main/fixes/fix-pm2-startup.sh
scp fix-pm2-startup.sh YOUR_USER@YOUR_SERVER_IP:~/
ssh YOUR_USER@YOUR_SERVER_IP "chmod +x fix-pm2-startup.sh && ./fix-pm2-startup.sh"
```

### Step 3: Restart your validator
```bash
# SSH into your server
ssh YOUR_USER@YOUR_SERVER_IP

# Stop everything and restart
pm2 stop all
tmux kill-server

# Start validator with fixed script
cd ~/splendor-blockchain-v4/Core-Blockchain
./node-start.sh --validator
```

### Step 4: Verify it works
```bash
# Check PM2 processes
pm2 list

# Check tmux sessions  
tmux ls

# You should see no more PM2 errors!
```

---

## What Gets Fixed

**Before:**
```
[PM2][ERROR] Script already launched, add -f option to force re-execution
```

**After:**
```
sync-helper is already running, restarting...
[PM2] [sync-helper](0) ✓
```

The fix adds:
- ✅ NVM environment sourcing (so PM2 works)
- ✅ PM2 process detection (prevents duplicate errors)
- ✅ Automatic restart of existing processes

---

## Troubleshooting

### "pm2: command not found"
You need to install NVM and PM2 first (see Step 1 above).

### "No such file or directory" 
Make sure your blockchain is in the right location:
- Check: `ls ~/splendor-blockchain-v4/Core-Blockchain/`
- Adjust paths in commands if your setup is different

### Still getting PM2 errors?
Your node-start.sh wasn't updated properly. Try Option A (copy the fixed file).

---

## Multiple Servers?

To fix multiple servers at once:

```bash
# Create server list
echo "user1@server1" > servers.txt
echo "user2@server2" >> servers.txt

# Fix all servers
while read server; do
    echo "Fixing $server..."
    scp Core-Blockchain/node-start.sh $server:~/splendor-blockchain-v4/Core-Blockchain/
    ssh $server "cd ~/splendor-blockchain-v4/Core-Blockchain && pm2 stop all && tmux kill-server && ./node-start.sh --validator"
done < servers.txt
```

That's it! Your PM2 errors should be gone and validators will restart properly.
