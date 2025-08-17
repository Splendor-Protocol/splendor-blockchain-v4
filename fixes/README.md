# PM2 Startup Error Fix

## ⚠️ For Validators/RPCs Prior to August 17, 2025 Only

This fix is **only needed for validators/RPC nodes deployed before August 17, 2025**.

If you deployed your validator after August 17, 2025, the PM2 fix is already included and you don't need this.

## What This Fixes

- ❌ `[PM2][ERROR] Script already launched, add -f option to force re-execution`
- ❌ `pm2: command not found`

## Files in this folder

- `PM2_STARTUP_FIX_GUIDE.md` - Complete guide to fix PM2 startup errors
- `fix-pm2-startup.sh` - Automated script to apply the fix

## Quick Start

1. **Check if you need this fix**: Try starting your validator. If you get PM2 errors, you need this fix.

2. **Follow the guide**: Open `PM2_STARTUP_FIX_GUIDE.md` for step-by-step instructions.

3. **Two options available**:
   - Copy the fixed node-start.sh file (easiest)
   - Run the automated fix script

## Need Auto-Start After Reboot?

If you want your validator to start automatically after server reboots, check the `auto-start/` folder for the auto-start service setup.
