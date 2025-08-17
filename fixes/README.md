# Splendor Validator Fixes

This folder contains fixes and guides for common Splendor validator issues.

## Available Fixes

### 1. PM2 Startup Error Fix
**File**: `PM2_STARTUP_FIX_GUIDE.md`  
**Script**: `fix-pm2-startup.sh`

**Fixes:**
- ❌ `[PM2][ERROR] Script already launched, add -f option to force re-execution`
- ❌ `pm2: command not found`

**When to use:** When your validator shows PM2 errors during startup.

---

### 2. Auto-Start Service Setup
**File**: `AUTO_START_SERVICE_GUIDE.md`  
**Script**: `create-autostart-service.sh`

**Fixes:**
- ❌ Manual validator restart after server reboots
- ❌ Validator not starting automatically

**When to use:** When you want your validator to start automatically after server reboots.

---

## Quick Start

### If you have PM2 errors:
1. Follow `PM2_STARTUP_FIX_GUIDE.md` first
2. Then optionally follow `AUTO_START_SERVICE_GUIDE.md`

### If you just want auto-start:
1. Make sure your validator works properly
2. Follow `AUTO_START_SERVICE_GUIDE.md`

---

## Files in this folder

```
fixes/
├── README.md                      # This file
├── PM2_STARTUP_FIX_GUIDE.md      # Guide to fix PM2 startup errors
├── AUTO_START_SERVICE_GUIDE.md   # Guide to setup auto-start service
├── fix-pm2-startup.sh            # Script to fix PM2 startup issues
└── create-autostart-service.sh   # Script to create auto-start service
```

---

## Need Help?

1. **PM2 Errors**: Start with `PM2_STARTUP_FIX_GUIDE.md`
2. **Auto-Start Issues**: Use `AUTO_START_SERVICE_GUIDE.md`
3. **Both Issues**: Fix PM2 errors first, then setup auto-start

All guides include troubleshooting sections and multiple server deployment examples.
