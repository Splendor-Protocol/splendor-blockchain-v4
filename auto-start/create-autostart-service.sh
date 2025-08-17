#!/bin/bash

# Splendor Validator Auto-Start Service Creator
# This script creates a systemd service to automatically start the validator after server reboots

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}    Splendor Validator Auto-Start Service${NC}"
echo -e "${CYAN}================================================${NC}"

# Find the splendor blockchain directory
BLOCKCHAIN_DIR=""
if [ -d "/root/splendor-blockchain-v4/Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="/root/splendor-blockchain-v4/Core-Blockchain"
elif [ -d "~/splendor-blockchain-v4/Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="~/splendor-blockchain-v4/Core-Blockchain"
elif [ -d "./Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="$(pwd)/Core-Blockchain"
else
    echo -e "${RED}Error: Could not find Core-Blockchain directory${NC}"
    echo -e "${ORANGE}Please run this script from the splendor-blockchain-v4 directory${NC}"
    exit 1
fi

# Convert to absolute path
BLOCKCHAIN_DIR=$(realpath "$BLOCKCHAIN_DIR")
echo -e "${GREEN}Found blockchain directory: $BLOCKCHAIN_DIR${NC}"

# Check if node-start.sh exists
if [ ! -f "$BLOCKCHAIN_DIR/node-start.sh" ]; then
    echo -e "${RED}Error: node-start.sh not found in $BLOCKCHAIN_DIR${NC}"
    exit 1
fi

# Determine node type by checking for existing nodes
NODE_TYPE=""
if [ -d "$BLOCKCHAIN_DIR/chaindata" ]; then
    if find "$BLOCKCHAIN_DIR/chaindata" -name ".validator" -type f | grep -q .; then
        NODE_TYPE="validator"
        echo -e "${GREEN}Detected: Validator node${NC}"
    elif find "$BLOCKCHAIN_DIR/chaindata" -name ".rpc" -type f | grep -q .; then
        NODE_TYPE="rpc"
        echo -e "${GREEN}Detected: RPC node${NC}"
    else
        echo -e "${ORANGE}Could not auto-detect node type. Please specify:${NC}"
        echo -e "1) Validator"
        echo -e "2) RPC"
        read -p "Enter choice (1/2): " choice
        case $choice in
            1) NODE_TYPE="validator" ;;
            2) NODE_TYPE="rpc" ;;
            *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
        esac
    fi
else
    echo -e "${ORANGE}No chaindata directory found. Assuming validator node.${NC}"
    NODE_TYPE="validator"
fi

# Create the systemd service file
SERVICE_FILE="/etc/systemd/system/splendor-validator.service"

echo -e "${ORANGE}Creating systemd service file...${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Splendor Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=$BLOCKCHAIN_DIR
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.nvm/versions/node/v21.7.1/bin
Environment=NVM_DIR=/root/.nvm
ExecStartPre=/bin/sleep 30
ExecStart=$BLOCKCHAIN_DIR/startup-wrapper.sh
ExecStop=$BLOCKCHAIN_DIR/node-stop.sh --$NODE_TYPE
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Service file created: $SERVICE_FILE${NC}"

# Create a startup wrapper script for better reliability
WRAPPER_SCRIPT="$BLOCKCHAIN_DIR/startup-wrapper.sh"

echo -e "${ORANGE}Creating startup wrapper script...${NC}"

cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash

# Splendor Validator Startup Wrapper
# This script ensures proper environment setup before starting the validator

# Wait for network to be fully ready
sleep 30

# Source NVM environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Change to the correct directory
cd "$(dirname "$0")"

# Determine node type
if [ -f "./chaindata/node1/.validator" ]; then
    NODE_TYPE="validator"
elif [ -f "./chaindata/node1/.rpc" ]; then
    NODE_TYPE="rpc"
else
    NODE_TYPE="validator"  # Default fallback
fi

# Start the node
exec ./node-start.sh --$NODE_TYPE
EOF

chmod +x "$WRAPPER_SCRIPT"
echo -e "${GREEN}✓ Wrapper script created: $WRAPPER_SCRIPT${NC}"

# Update the service file to use the wrapper
sed -i "s|ExecStart=.*|ExecStart=$WRAPPER_SCRIPT|" "$SERVICE_FILE"

# Reload systemd and enable the service
echo -e "${ORANGE}Enabling systemd service...${NC}"
systemctl daemon-reload
systemctl enable splendor-validator.service

echo -e "${GREEN}✓ Service enabled and will start automatically on boot${NC}"

# Check if PM2 startup is configured
echo -e "${ORANGE}Configuring PM2 startup...${NC}"

# Source NVM for PM2 commands
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if command -v pm2 >/dev/null 2>&1; then
    pm2 startup systemd -u root --hp /root
    echo -e "${GREEN}✓ PM2 startup configured${NC}"
else
    echo -e "${ORANGE}PM2 not found in PATH, skipping PM2 startup configuration${NC}"
fi

echo -e "\n${CYAN}=== Auto-Start Service Setup Complete ===${NC}"
echo -e "${GREEN}✓ Systemd service created and enabled${NC}"
echo -e "${GREEN}✓ Startup wrapper script created${NC}"
echo -e "${GREEN}✓ PM2 startup configured${NC}"
echo -e "${GREEN}✓ Node will automatically start after server reboots${NC}"

echo -e "\n${CYAN}Service Management Commands:${NC}"
echo -e "• Start service:   ${ORANGE}systemctl start splendor-validator${NC}"
echo -e "• Stop service:    ${ORANGE}systemctl stop splendor-validator${NC}"
echo -e "• Check status:    ${ORANGE}systemctl status splendor-validator${NC}"
echo -e "• View logs:       ${ORANGE}journalctl -u splendor-validator -f${NC}"
echo -e "• Disable service: ${ORANGE}systemctl disable splendor-validator${NC}"

echo -e "\n${ORANGE}Note: The service will wait 30 seconds after boot before starting${NC}"
echo -e "${ORANGE}to ensure network connectivity is fully established.${NC}"

echo -e "\n${GREEN}Setup complete! Your validator will now start automatically after reboots.${NC}"
