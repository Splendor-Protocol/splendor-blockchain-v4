#!/bin/bash

# Splendor Blockchain Monitor Setup Script
# This script sets up the monitoring system for validators and RPC nodes

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "=================================================="
echo "  Splendor Blockchain Monitor Setup"
echo "=================================================="
echo -e "${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js 14+ first.${NC}"
    echo "You can install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo -e "${RED}Error: Node.js version 14 or higher is required. Current version: $(node -v)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node -v) detected${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ npm $(npm -v) detected${NC}"

# Check if PM2 is installed globally
if ! command -v pm2 &> /dev/null; then
    echo -e "${ORANGE}PM2 not found. Installing PM2 globally...${NC}"
    npm install -g pm2
    echo -e "${GREEN}✓ PM2 installed${NC}"
else
    echo -e "${GREEN}✓ PM2 $(pm2 -v) detected${NC}"
fi

# Install dependencies
echo -e "${CYAN}Installing Node.js dependencies...${NC}"
npm install

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${CYAN}Creating .env configuration file...${NC}"
    cp .env.example .env
    echo -e "${ORANGE}Please edit the .env file to configure your notification settings.${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Make scripts executable
chmod +x monitor.js
chmod +x dashboard.js

echo -e "${GREEN}✓ Scripts made executable${NC}"

# Create systemd service file (optional)
create_systemd_service() {
    echo -e "${CYAN}Creating systemd service for monitoring...${NC}"
    
    SERVICE_FILE="/etc/systemd/system/splendor-monitor.service"
    CURRENT_DIR=$(pwd)
    CURRENT_USER=$(whoami)
    
    sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Splendor Blockchain Monitor
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$CURRENT_DIR
ExecStart=/usr/bin/node $CURRENT_DIR/monitor.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable splendor-monitor.service
    
    echo -e "${GREEN}✓ Systemd service created and enabled${NC}"
    echo -e "${CYAN}You can start the service with: sudo systemctl start splendor-monitor${NC}"
}

# Create PM2 ecosystem file
echo -e "${CYAN}Creating PM2 ecosystem configuration...${NC}"

cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [
    {
      name: 'splendor-monitor',
      script: './monitor.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/monitor-error.log',
      out_file: './logs/monitor-out.log',
      log_file: './logs/monitor-combined.log',
      time: true
    },
    {
      name: 'splendor-dashboard',
      script: './dashboard.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        DASHBOARD_PORT: 3001
      },
      error_file: './logs/dashboard-error.log',
      out_file: './logs/dashboard-out.log',
      log_file: './logs/dashboard-combined.log',
      time: true
    }
  ]
};
EOF

# Create logs directory
mkdir -p logs

echo -e "${GREEN}✓ PM2 ecosystem configuration created${NC}"

# Function to display usage instructions
show_usage() {
    echo -e "${GREEN}"
    echo "=================================================="
    echo "  Setup Complete!"
    echo "=================================================="
    echo -e "${NC}"
    echo -e "${CYAN}Configuration:${NC}"
    echo "1. Edit the .env file to configure notifications:"
    echo "   nano .env"
    echo ""
    echo -e "${CYAN}Starting the Monitor:${NC}"
    echo ""
    echo -e "${ORANGE}Option 1: Using PM2 (Recommended)${NC}"
    echo "  pm2 start ecosystem.config.js"
    echo "  pm2 save"
    echo "  pm2 startup  # Follow the instructions to enable auto-start"
    echo ""
    echo -e "${ORANGE}Option 2: Direct execution${NC}"
    echo "  # Monitor only:"
    echo "  node monitor.js"
    echo ""
    echo "  # Monitor + Dashboard:"
    echo "  node dashboard.js"
    echo ""
    echo -e "${ORANGE}Option 3: Using systemd${NC}"
    echo "  sudo systemctl start splendor-monitor"
    echo "  sudo systemctl status splendor-monitor"
    echo ""
    echo -e "${CYAN}Accessing the Dashboard:${NC}"
    echo "  http://localhost:3001"
    echo ""
    echo -e "${CYAN}Managing with PM2:${NC}"
    echo "  pm2 status           # Check status"
    echo "  pm2 logs             # View logs"
    echo "  pm2 restart all      # Restart services"
    echo "  pm2 stop all         # Stop services"
    echo ""
    echo -e "${ORANGE}Note: Make sure your blockchain nodes are running before starting the monitor.${NC}"
}

# Ask user if they want to create systemd service
echo ""
read -p "Do you want to create a systemd service? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    create_systemd_service
fi

show_usage

echo -e "${GREEN}Setup completed successfully!${NC}"
