# RPC Server CORS Header Issue Analysis
**Date:** August 11, 2025  
**Server:** mainnet-rpc.splendor.org (72.60.24.227)  
**Issue:** Duplicate Access-Control-Allow-Origin headers  

## Problem Identified

The RPC server at https://mainnet-rpc.splendor.org is sending **duplicate** `Access-Control-Allow-Origin` headers, which causes CORS errors in web browsers.

### Evidence from HTTP Response:
```
HTTP/2 200
date: Mon, 11 Aug 2025 12:58:38 GMT
server: cloudflare
access-control-allow-origin: *
access-control-allow-origin: *    <-- DUPLICATE HEADER
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=..."}]}
vary: Origin
vary: accept-encoding
access-control-allow-methods: GET, POST, OPTIONS
access-control-allow-headers: DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range
```

## Root Cause Analysis

### 1. Nginx Configuration Issue
**File:** `/etc/nginx/sites-available/mainnet-rpc.splendor.org`

The nginx configuration has **duplicate CORS header declarations**:

```nginx
location / {
    proxy_pass http://72.60.24.227:80;
    proxy_set_header Host rpc.splendor.org;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # CORS headers for RPC (FIRST SET)
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
    add_header Access-Control-Allow-Headers 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';

    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin *;    # SECOND SET (DUPLICATE)
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
        add_header Access-Control-Allow-Headers 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Type 'text/plain; charset=utf-8';
        add_header Content-Length 0;
        return 204;
    }
}
```

### 2. Backend Geth Configuration
**Process:** Geth node running on port 80
**Command:** 
```bash
../../node_src/build/bin/geth --datadir . --syncmode full --gcmode archive --http --http.addr 0.0.0.0 --http.port 80 --http.corsdomain "*" --http.vhosts "*" --ws --ws.addr 0.0.0.0 --ws.port 8545 --ws.origins "*" --http.api "admin,debug,web3,eth,txpool,personal,congress,miner,net" --networkid 2691 --bootnodes "enode://..." console
```

**Note:** Geth is configured with `--http.corsdomain "*"` which means it's also adding CORS headers.

## The Problem Explained

1. **Geth Backend** adds `Access-Control-Allow-Origin: *` header
2. **Nginx Proxy** adds another `Access-Control-Allow-Origin: *` header
3. **Result:** Browser receives duplicate headers and rejects the request

## Browser Behavior

Modern browsers (Chrome, Firefox, Safari) **reject** HTTP responses that contain duplicate `Access-Control-Allow-Origin` headers, even if both headers have the same value. This is per the CORS specification.

## Current Server Architecture

```
Internet → Cloudflare → Nginx (Port 443) → Geth (Port 80)
                           ↓                    ↓
                    Adds CORS headers    Adds CORS headers
                                         ↓
                              DUPLICATE HEADERS
```

## Impact

**Current Status:** The duplicate header issue affects specific request types:

**Working:**
- MetaMask connections are functional
- Dashboard applications are operational  
- OPTIONS preflight requests (show single header)

**Affected:**
- **blokcscount service is experiencing CORS failures**
- POST requests to RPC endpoint show duplicate headers
- Browser-based applications making JSON-RPC POST calls may fail

**Technical Details:**
- OPTIONS requests: Single `access-control-allow-origin: *` header ✅
- POST requests: Duplicate `access-control-allow-origin: *` headers ❌
- This explains why some services work while blokcscount fails

## Recommended Solutions (OBSERVATION ONLY)

### Option 1: Whitelist Specific Origins (Recommended for Security)
Use nginx map directive to whitelist specific origins like blokcscount/explorer:

```nginx
# Add to nginx.conf or site config (outside server block)
map $http_origin $cors_origin {
    default "";
    "~^https?://explorer\.splendor\.org$" $http_origin;
    "~^https?://blokcscount\.com$" $http_origin;
    "~^https?://.*\.blokcscount\.com$" $http_origin;
}

# In server block, replace current CORS headers with:
add_header Access-Control-Allow-Origin $cors_origin;
```

### Option 2: Remove CORS from Nginx
Since Geth is already handling CORS with `--http.corsdomain "*"`, remove the CORS headers from nginx configuration.

### Option 3: Remove CORS from Geth
Remove `--http.corsdomain "*"` from Geth startup and let nginx handle all CORS.

### Option 4: Use proxy_hide_header
Use nginx directive to hide backend CORS headers and only use nginx ones.

## Current Status

- **Issue Confirmed:** Duplicate `Access-Control-Allow-Origin` headers detected
- **Impact:** High - Blocking blokcscount and other JSON-RPC POST-based services
- **Urgency:** High - Affecting specific blockchain analytics and explorer services
- **Solution Required:** Clean up duplicate CORS header configuration for optimal compliance

## Technical Details

- **Server:** Ubuntu with nginx 1.x
- **SSL:** Configured with valid certificate
- **Cloudflare:** Acting as CDN/proxy (not causing the issue)
- **Backend:** Geth node with HTTP RPC enabled
- **Port Configuration:** nginx:443 → geth:80

---
**Note:** This analysis was conducted through observation only. No changes were made to the server configuration.
