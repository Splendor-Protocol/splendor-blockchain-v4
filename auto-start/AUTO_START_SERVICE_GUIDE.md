# Auto-Start Service Setup Guide

## What This Does
- ✅ Automatically starts your validator/RPC after server reboots
- ✅ Creates a systemd service that manages your node
- ✅ Ensures your node restarts if it crashes

## Prerequisites
- Your validator must be working properly first
- If you have PM2 errors, fix those first using the PM2_STARTUP_FIX_GUIDE.md

## Setup Auto-Start Service

### Step 1: Copy the auto-start script
```bash
# From your local machine
scp fixes/create-autostart-service.sh YOUR_USER@YOUR_SERVER_IP:~/
```

### Step 2: SSH and run the script
```bash
# SSH into your server
ssh YOUR_USER@YOUR_SERVER_IP

# Make it executable and run
chmod +x create-autostart-service.sh
./create-autostart-service.sh
```

### Step 3: Test the service
```bash
# Check service status
systemctl status splendor-validator

# Test manual start/stop
systemctl stop splendor-validator
systemctl start splendor-validator
systemctl status splendor-validator
```

---

## Testing Auto-Start

### Test 1: Reboot Test
```bash
# Reboot your server
sudo reboot

# After reboot, check if validator started automatically
systemctl status splendor-validator
tmux ls  # Should show node1 session
pm2 list  # Should show sync-helper running
```

### Test 2: Service Logs
```bash
# View real-time logs
journalctl -u splendor-validator -f

# View recent logs
journalctl -u splendor-validator -n 50
```

---

## Service Management Commands

After setup, you can manage your validator service:

```bash
# Check service status
systemctl status splendor-validator

# Start/stop service manually
systemctl start splendor-validator
systemctl stop splendor-validator

# Enable/disable auto-start
systemctl enable splendor-validator   # Enable auto-start
systemctl disable splendor-validator  # Disable auto-start

# View logs
journalctl -u splendor-validator -f   # Real-time logs
journalctl -u splendor-validator -n 50  # Last 50 lines
```

---

## What the Script Creates

The auto-start script creates:

1. **Systemd Service File**: `/etc/systemd/system/splendor-validator.service`
2. **Startup Wrapper Script**: `~/splendor-blockchain-v4/Core-Blockchain/startup-wrapper.sh`
3. **PM2 Startup Configuration**: Configures PM2 to survive reboots

### Service Features:
- ✅ **Network wait**: Waits 30 seconds for network to be ready
- ✅ **Auto-detection**: Automatically determines if validator or RPC node
- ✅ **Environment setup**: Properly configures NVM and PM2 environment
- ✅ **Failure recovery**: Automatically restarts if the service fails

---

## Troubleshooting

### Service won't start after reboot
```bash
# Check service logs for errors
journalctl -u splendor-validator -n 50

# Common issues:
# - Network not ready (service waits 30s, some networks need longer)
# - NVM path issues (check Node.js path in service file)
# - Permission issues (ensure scripts are executable)
```

### Service shows "failed" status
```bash
# Check what went wrong
systemctl status splendor-validator
journalctl -u splendor-validator -n 20

# Try manual start to see errors
systemctl start splendor-validator
```

### Validator starts but PM2 doesn't work
This means you need to fix the PM2 startup issue first. See `PM2_STARTUP_FIX_GUIDE.md`.

---

## Multiple Servers Setup

To set up auto-start on multiple servers:

```bash
# Create server list
echo "user1@server1" > servers.txt
echo "user2@server2" >> servers.txt

# Deploy to all servers
while read server; do
    echo "Setting up auto-start on $server..."
    scp fixes/create-autostart-service.sh $server:~/
    ssh $server "chmod +x create-autostart-service.sh && ./create-autostart-service.sh"
    echo "Auto-start setup complete on $server!"
done < servers.txt
```

---

## Removing Auto-Start

If you want to remove the auto-start service:

```bash
# Stop and disable the service
systemctl stop splendor-validator
systemctl disable splendor-validator

# Remove service file
sudo rm /etc/systemd/system/splendor-validator.service

# Reload systemd
systemctl daemon-reload

# Remove startup wrapper (optional)
rm ~/splendor-blockchain-v4/Core-Blockchain/startup-wrapper.sh
```

That's it! Your validator will now start automatically after server reboots.
