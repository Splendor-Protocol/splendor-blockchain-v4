# Splendor Blockchain Monitor

A comprehensive monitoring system for Splendor blockchain validators, RPC nodes, and services with real-time notifications and web dashboard.

## Features

- **Real-time Monitoring**: Continuously monitors validator nodes, RPC endpoints, and PM2 services
- **Multiple Notification Channels**: Email, Slack, and webhook notifications
- **Web Dashboard**: Beautiful real-time dashboard with status overview, alerts, and logs
- **Health Checks**: Monitors tmux sessions, RPC endpoint responses, and service status
- **Automatic Recovery Detection**: Notifies when services come back online
- **Comprehensive Logging**: Detailed logs with different severity levels
- **Easy Setup**: Automated setup script with multiple deployment options

## Quick Start

1. **Navigate to the monitoring directory**:
   ```bash
   cd monitoring
   ```

2. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Configure notifications** (optional):
   ```bash
   nano .env
   ```

4. **Start monitoring**:
   ```bash
   pm2 start ecosystem.config.js
   pm2 save
   ```

5. **Access the dashboard**:
   Open http://localhost:3001 in your browser

## What It Monitors

### Validators
- Monitors tmux sessions for validator nodes (node1, node2, etc.)
- Checks for error messages in validator output
- Detects when validators go offline or come back online

### RPC Nodes
- HTTP RPC endpoints (default: port 80)
- WebSocket endpoints (default: port 8545)
- Response time monitoring
- Block number verification

### Services
- PM2 managed services (like sync-helper)
- Service status, memory usage, and restart counts
- Automatic detection of service failures and recoveries

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Email Notifications
EMAIL_NOTIFICATIONS=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM=your-email@gmail.com
EMAIL_TO=admin@yourdomain.com

# Slack Notifications
SLACK_NOTIFICATIONS=true
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

# Webhook Notifications
WEBHOOK_NOTIFICATIONS=true
WEBHOOK_URL=https://your-webhook-url.com/alerts

# Server Configuration
IP=your-server-ip

# Monitoring Settings
CHECK_INTERVAL=30000  # 30 seconds
RPC_TIMEOUT=10000     # 10 seconds
```

### Notification Setup

#### Email Notifications
1. Enable 2FA on your Gmail account
2. Generate an App Password
3. Use the App Password in `SMTP_PASS`

#### Slack Notifications
1. Create a Slack App in your workspace
2. Add Incoming Webhooks feature
3. Copy the webhook URL to `SLACK_WEBHOOK_URL`

#### Webhook Notifications
Configure any HTTP endpoint to receive JSON alerts:
```json
{
  "title": "Validator Node Down",
  "message": "node1 has gone offline...",
  "severity": "critical",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Deployment Options

### Option 1: PM2 (Recommended)
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Follow instructions for auto-start
```

### Option 2: Direct Execution
```bash
# Monitor only
node monitor.js

# Monitor + Dashboard
node dashboard.js
```

### Option 3: Systemd Service
```bash
# Created automatically by setup.sh if requested
sudo systemctl start splendor-monitor
sudo systemctl enable splendor-monitor
```

## Dashboard Features

The web dashboard provides:

- **System Summary**: Overview of all monitored components
- **Real-time Status**: Live status of validators, RPC nodes, and services
- **Alert History**: Recent alerts with severity levels
- **System Logs**: Live log viewer with filtering
- **Auto-refresh**: Updates every 30 seconds
- **Responsive Design**: Works on desktop and mobile

## API Endpoints

The dashboard exposes REST API endpoints:

- `GET /api/status` - Current system status
- `GET /api/alerts?limit=50` - Recent alerts
- `GET /api/logs` - System logs

## File Structure

```
monitoring/
├── monitor.js          # Main monitoring script
├── dashboard.js        # Web dashboard server
├── package.json        # Node.js dependencies
├── setup.sh           # Automated setup script
├── .env.example       # Configuration template
├── README.md          # This file
├── ecosystem.config.js # PM2 configuration (created by setup)
├── public/
│   └── index.html     # Dashboard web interface
└── logs/              # Log files (created automatically)
```

## Troubleshooting

### Monitor Not Starting
1. Check Node.js version: `node -v` (requires 14+)
2. Install dependencies: `npm install`
3. Check configuration: `cat .env`

### No Validators Detected
1. Ensure validator nodes are running in tmux sessions
2. Check session names: `tmux list-sessions`
3. Verify sessions start with "node": `node1`, `node2`, etc.

### RPC Endpoints Not Responding
1. Check if RPC nodes are running
2. Verify IP and port configuration in `.env`
3. Test manually: `curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://your-ip:80`

### Dashboard Not Accessible
1. Check if dashboard is running: `pm2 status`
2. Verify port 3001 is not blocked by firewall
3. Check dashboard logs: `pm2 logs splendor-dashboard`

### Notifications Not Working
1. Verify notification settings in `.env`
2. Test email settings with a simple test
3. Check webhook URLs are accessible
4. Verify Slack webhook URL format

## Monitoring Best Practices

1. **Regular Health Checks**: Monitor runs every 30 seconds by default
2. **Alert Fatigue**: Configure appropriate notification thresholds
3. **Log Rotation**: Monitor log file sizes and rotate as needed
4. **Backup Configuration**: Keep `.env` file backed up securely
5. **Network Monitoring**: Ensure monitoring server has stable network connection

## Security Considerations

- Store sensitive credentials in `.env` file (not in version control)
- Use app passwords for email authentication
- Restrict dashboard access with reverse proxy if needed
- Monitor the monitoring system itself for failures

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review system logs: `pm2 logs` or `journalctl -u splendor-monitor`
3. Verify blockchain nodes are running properly
4. Check network connectivity between monitoring system and nodes

## License

MIT License - see LICENSE file for details.
