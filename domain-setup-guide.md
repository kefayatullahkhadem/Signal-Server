# Signal Server Domain Setup Guide

Setting up domains for your Signal Server. This guide documents the actual implementation steps completed.

## Server Details

- **Server IPv6**: `2a02:c207:2272:5596::1`
- **Server IPv4**: `84.247.188.3`
- **Main Domain**: `signal.testers.fun`
- **API Domain**: `api.testers.fun`
- **WebSocket Domain**: `ws.testers.fun`
- **Local API**: `http://localhost:8080`
- **Local WebSocket**: `ws://localhost:8444`

## COMPLETED IMPLEMENTATION STEPS

### ✅ Step 1: Server Preparation
```bash
$ curl ifconfig.me
2a02:c207:2272:5596::1
```

### ✅ Step 2: Nginx Installation
```bash
$ sudo apt update && sudo apt install -y nginx
$ sudo systemctl start nginx && sudo systemctl enable nginx  
$ sudo ufw allow 'Nginx Full' && sudo ufw allow ssh && sudo ufw --force enable
```

### ✅ Step 3: SSL Certificate Tools
```bash
$ sudo apt install -y certbot python3-certbot-nginx
```

### ✅ Step 4: Nginx Proxy Configuration
Created `/etc/nginx/sites-available/signal-server` with proxy configuration for:
- `signal.testers.fun` → `http://127.0.0.1:8080` (API)
- `api.testers.fun` → `http://127.0.0.1:8080` (API)  
- `ws.testers.fun` → `http://127.0.0.1:8444` (WebSocket)

```bash
$ sudo ln -s /etc/nginx/sites-available/signal-server /etc/nginx/sites-enabled/
$ sudo nginx -t  # ✅ Configuration valid
$ sudo systemctl reload nginx  # ✅ Applied successfully
```

## 🚨 REQUIRED: DNS Configuration

**Add these DNS records to your domain registrar:**

```
Type    Name     Value                        TTL
A       signal   84.247.188.3                300
A       api      84.247.188.3                300  
A       ws       84.247.188.3                300
AAAA    signal   2a02:c207:2272:5596::1      300
AAAA    api      2a02:c207:2272:5596::1      300
AAAA    ws       2a02:c207:2272:5596::1      300
```

## Final Steps (After DNS Configuration)

1. **Wait 5-10 minutes** for DNS propagation
2. **Test DNS resolution:**
   ```bash
   $ nslookup signal.testers.fun
   ```
3. **Get SSL certificates:**
   ```bash
   $ sudo certbot --nginx -d signal.testers.fun -d api.testers.fun -d ws.testers.fun --non-interactive --agree-tos --email admin@testers.fun
   ```

## Final Access URLs

✅ **COMPLETED**: DNS and SSL are configured:
- **Main API**: `https://signal.testers.fun` or `https://api.testers.fun`
- **WebSocket**: `wss://ws.testers.fun`

## Status Summary

✅ **Server configured and ready**  
✅ **Nginx proxy configured**  
✅ **SSL tools installed**  
✅ **DNS configuration complete**  
✅ **SSL certificates installed**

## Next Steps for Android App

Once the domain is fully configured, update your Android Signal app with these URLs:

```java
// In your Android app configuration
public static final String SIGNAL_URL = "https://api.testers.fun";
public static final String SIGNAL_WEBSOCKET_URL = "wss://ws.testers.fun";
```