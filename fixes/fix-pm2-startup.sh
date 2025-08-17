#!/bin/bash

# PM2 Startup Fix Script
# This script automatically fixes the PM2 duplicate startup issue in node-start.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}    PM2 Startup Issue Auto-Fix Script${NC}"
echo -e "${CYAN}========================================${NC}"

# Find the splendor blockchain directory
BLOCKCHAIN_DIR=""
if [ -d "/root/splendor-blockchain-v4/Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="/root/splendor-blockchain-v4/Core-Blockchain"
elif [ -d "~/splendor-blockchain-v4/Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="~/splendor-blockchain-v4/Core-Blockchain"
elif [ -d "./Core-Blockchain" ]; then
    BLOCKCHAIN_DIR="./Core-Blockchain"
else
    echo -e "${RED}Error: Could not find Core-Blockchain directory${NC}"
    echo -e "${ORANGE}Please run this script from the splendor-blockchain-v4 directory or ensure the path exists${NC}"
    exit 1
fi

echo -e "${GREEN}Found blockchain directory: $BLOCKCHAIN_DIR${NC}"

# Check if node-start.sh exists
if [ ! -f "$BLOCKCHAIN_DIR/node-start.sh" ]; then
    echo -e "${RED}Error: node-start.sh not found in $BLOCKCHAIN_DIR${NC}"
    exit 1
fi

# Create backup
echo -e "${ORANGE}Creating backup of original node-start.sh...${NC}"
cp "$BLOCKCHAIN_DIR/node-start.sh" "$BLOCKCHAIN_DIR/node-start.sh.backup.$(date +%Y%m%d_%H%M%S)"

# Check if the fix is already applied
if grep -q "# Check if sync-helper is already running" "$BLOCKCHAIN_DIR/node-start.sh"; then
    echo -e "${GREEN}PM2 fix already applied! Checking if it needs updates...${NC}"
    
    # Check if NVM sourcing is present
    if ! grep -q "export NVM_DIR" "$BLOCKCHAIN_DIR/node-start.sh"; then
        echo -e "${ORANGE}Adding NVM environment sourcing...${NC}"
        sed -i '/cd \.\/plugins\/sync-helper\//a\\n  # Source NVM environment to access pm2\n  export NVM_DIR="$HOME/.nvm"\n  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' "$BLOCKCHAIN_DIR/node-start.sh"
    fi
    
    echo -e "${GREEN}Fix is up to date!${NC}"
    exit 0
fi

echo -e "${ORANGE}Applying PM2 startup fix...${NC}"

# Apply the fix - replace the problematic PM2 section
sed -i '/cd \.\/plugins\/sync-helper\//,/cd \.\.\/\.\.\//{
    /cd \.\/plugins\/sync-helper\//a\\n  # Source NVM environment to access pm2\n  export NVM_DIR="$HOME/.nvm"\n  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n\n  # Check if sync-helper is already running\n  if pm2 list | grep -q "sync-helper"; then\n    echo -e "${ORANGE}sync-helper is already running, restarting...${NC}"\n    pm2 restart sync-helper\n  else\n    echo -e "${GREEN}Starting sync-helper...${NC}"\n    pm2 start index.js --name "sync-helper"\n  fi\n  \n  pm2 save
    /^  pm2 start index\.js$/d
    /^  pm2 save$/d
}' "$BLOCKCHAIN_DIR/node-start.sh"

# Verify the fix was applied
if grep -q "# Check if sync-helper is already running" "$BLOCKCHAIN_DIR/node-start.sh"; then
    echo -e "${GREEN}✓ PM2 startup fix successfully applied!${NC}"
    echo -e "${GREEN}✓ Backup created with timestamp${NC}"
    echo -e "${GREEN}✓ The script will now handle existing PM2 processes gracefully${NC}"
    
    echo -e "\n${CYAN}What was fixed:${NC}"
    echo -e "• Added PM2 process detection before starting"
    echo -e "• Added NVM environment sourcing for PM2 access"
    echo -e "• Changed behavior to restart existing processes instead of failing"
    echo -e "• Eliminated '[PM2][ERROR] Script already launched' errors"
    
    echo -e "\n${GREEN}Fix complete! The node-start.sh script will now work without PM2 errors.${NC}"
else
    echo -e "${RED}Error: Fix may not have been applied correctly${NC}"
    echo -e "${ORANGE}Please check the node-start.sh file manually${NC}"
    exit 1
fi
