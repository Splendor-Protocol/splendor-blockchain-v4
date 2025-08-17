# Auto-Start Service Setup

## What This Does

- ✅ Automatically starts your validator after server reboots
- ✅ Creates a systemd service that manages your validator
- ✅ Ensures validator restarts if it crashes

## Prerequisites

- Your validator must be working properly first
- If you have PM2 errors, fix those first using the `fixes/` folder

## Files in this folder

- `AUTO_START_SERVICE_GUIDE.md` - Complete guide to setup auto-start service
- `create-autostart-service.sh` - Script to create the systemd service

## Quick Start

1. **Make sure your validator works**: Test that your validator starts properly without errors.

2. **Follow the guide**: Open `AUTO_START_SERVICE_GUIDE.md` for step-by-step instructions.

3. **Run the setup script**: The script will automatically create the systemd service for you.

## This is Optional

Auto-start is a **convenience feature**. Your validator will work fine without it - you'll just need to manually start it after server reboots.

## Need PM2 Fix?

If your validator shows PM2 errors during startup, check the `fixes/` folder first to fix those issues before setting up auto-start.
