# Signal Android App - Server Configuration Guide

This guide shows how to configure the official Signal Android app to connect to your custom Signal Server instead of the official Signal servers.

## Prerequisites

- Signal Android source code from GitHub
- Android Studio
- Custom Signal Server running (see `starting-and-building-the-server.md`)
- Your server domains configured with SSL certificates

## Server Information

**Your Custom Server URLs:**
- **API Server**: `https://api.testers.fun`
- **WebSocket**: `wss://ws.testers.fun`
- **CDN**: `https://signal.testers.fun` (or use API server)
- **Storage Service**: `https://api.testers.fun` (or setup separate)

## Step-by-Step Configuration

### Step 1: Clone Signal Android Repository

```bash
# Clone the official Signal Android repository
git clone https://github.com/signalapp/Signal-Android.git
cd Signal-Android

# Create a new branch for your custom configuration
git checkout -b custom-server-config
```

### Step 2: Locate Configuration Files

The main configuration files you need to modify:

```
app/src/main/java/org/thoughtcrime/securesms/
├── BuildConfig.java (auto-generated)
├── push/
│   └── SignalServiceNetworkAccess.java
└── dependencies/
    └── ApplicationDependencies.java

app/src/main/res/
├── values/
│   ├── strings.xml
│   └── arrays.xml
└── xml/
    └── network_security_config.xml

gradle files:
├── app/build.gradle
└── build.gradle
```

### Step 3: Modify Server URLs

#### A. Edit `app/build.gradle`

Find the `buildTypes` section and modify the server URLs:

```gradle
android {
    // ... other configurations

    buildTypes {
        debug {
            buildConfigField "String", "SIGNAL_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_CDN_URL", "\"https://signal.testers.fun\""
            buildConfigField "String", "SIGNAL_CDN2_URL", "\"https://signal.testers.fun\""
            buildConfigField "String", "SIGNAL_CONTACT_DISCOVERY_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_KEY_BACKUP_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_STORAGE_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_SFU_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "CONTENT_PROXY_HOST", "\"contentproxy.signal.org\""
            buildConfigField "int", "CONTENT_PROXY_PORT", "443"
            buildConfigField "String", "USER_AGENT", "\"Signal-Android\""
            
            // WebSocket URL
            buildConfigField "String", "SIGNAL_SERVICE_STATUS_URL", "\"uptime.signal.org\""
            buildConfigField "String", "SIGNAL_KEY_BACKUP_SERVICE_URL", "\"https://api.testers.fun\""
            
            // Certificate pinning - we'll disable this for custom server
            buildConfigField "boolean", "ENABLE_CERT_PINNING", "false"
        }
        
        release {
            // Copy the same configuration as debug for your custom server
            buildConfigField "String", "SIGNAL_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_CDN_URL", "\"https://signal.testers.fun\""
            buildConfigField "String", "SIGNAL_CDN2_URL", "\"https://signal.testers.fun\""
            buildConfigField "String", "SIGNAL_CONTACT_DISCOVERY_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_KEY_BACKUP_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_STORAGE_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "SIGNAL_SFU_URL", "\"https://api.testers.fun\""
            buildConfigField "String", "CONTENT_PROXY_HOST", "\"contentproxy.signal.org\""
            buildConfigField "int", "CONTENT_PROXY_PORT", "443"
            buildConfigField "String", "USER_AGENT", "\"Signal-Android\""
            buildConfigField "String", "SIGNAL_SERVICE_STATUS_URL", "\"uptime.signal.org\""
            buildConfigField "String", "SIGNAL_KEY_BACKUP_SERVICE_URL", "\"https://api.testers.fun\""
            buildConfigField "boolean", "ENABLE_CERT_PINNING", "false"
            
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### B. Modify WebSocket Configuration

Find the file that handles WebSocket connections (usually in `libsignal-service-java` or similar):

Look for files containing WebSocket URLs and change them to:
```java
private static final String SIGNAL_WEBSOCKET_URL = "wss://ws.testers.fun";
```

### Step 4: Disable Certificate Pinning

Signal uses certificate pinning for security. You need to disable this for your custom server.

#### A. Find Certificate Pinning Code

Look for files containing certificate pinning logic:
```bash
grep -r "CertificatePinner" app/src/
grep -r "pin-sha256" app/src/
grep -r "truststore" app/src/
```

#### B. Modify Network Security Config

Edit `app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <!-- Your custom domains -->
        <domain includeSubdomains="true">testers.fun</domain>
        <domain includeSubdomains="true">api.testers.fun</domain>
        <domain includeSubdomains="true">ws.testers.fun</domain>
        <domain includeSubdomains="true">signal.testers.fun</domain>
        
        <!-- Trust system and user-added CAs -->
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </domain-config>
    
    <!-- Default configuration for other domains -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

#### C. Disable Pinning in Code

Find and modify certificate pinning code. Look for classes like:
- `SignalServiceNetworkAccess`
- `PinningTrustManager` 
- Any OkHttp client configurations

Example modification:
```java
// Original code with pinning
OkHttpClient.Builder builder = new OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .connectTimeout(30, TimeUnit.SECONDS);

// Modified code without pinning
OkHttpClient.Builder builder = new OkHttpClient.Builder()
    .connectTimeout(30, TimeUnit.SECONDS);
    // Remove .certificatePinner(certificatePinner) line
```

### Step 5: Update Application Dependencies

Find `ApplicationDependencies.java` or similar dependency injection files and ensure they use your BuildConfig values:

```java
public class ApplicationDependencies {
    // ... other code

    private static SignalServiceNetworkAccess provideSignalServiceNetworkAccess() {
        return new SignalServiceNetworkAccess(ApplicationContext.getInstance())
            .configure(
                BuildConfig.SIGNAL_URL,
                BuildConfig.SIGNAL_CDN_URL,
                BuildConfig.SIGNAL_CDN2_URL,
                // ... other URLs
            );
    }
}
```

### Step 6: Modify Push Service Configuration

Find push notification service configuration and update Google Cloud Messaging (GCM) or Firebase Cloud Messaging (FCM) settings if needed.

Look for:
```java
// Update server endpoints for push notifications
private static final String PUSH_SERVICE_URL = BuildConfig.SIGNAL_URL + "/v1/messages";
```

### Step 7: Update Service URLs in Constants

Find constant definitions (often in a `Constants.java` or `Config.java` file):

```java
public class Constants {
    // Replace these with your server URLs
    public static final String SIGNAL_SERVICE_URL = BuildConfig.SIGNAL_URL;
    public static final String SIGNAL_CDN_URL = BuildConfig.SIGNAL_CDN_URL;
    public static final String SIGNAL_WEBSOCKET_URL = "wss://ws.testers.fun";
    
    // Disable certificate pinning
    public static final boolean ENABLE_CERTIFICATE_PINNING = false;
}
```

### Step 8: Handle Registration and SMS

Your test server accepts any phone verification code. Find the SMS verification code in:

```java
// Look for SMS verification logic and note that test server accepts any code
// File: typically in registration or verification package
public class SmsVerificationHandler {
    // The test server accepts any string for phone verification
    // So "123456" or any code will work
}
```

### Step 9: Build Configuration Changes

#### A. Update App Name and Package

In `app/build.gradle`, you might want to change the application ID to avoid conflicts:

```gradle
android {
    defaultConfig {
        applicationId "org.thoughtcrime.securesms.custom"  // Changed from original
        // ... other configs
    }
}
```

#### B. Update App Strings

In `app/src/main/res/values/strings.xml`:

```xml
<resources>
    <string name="app_name">Signal Custom</string>
    <!-- Update other relevant strings -->
</resources>
```

### Step 10: Test Server Integration

Add test endpoints to verify your server connection:

```java
// Add this to test your server connection
public class ServerConnectionTest {
    public static void testConnection() {
        try {
            String url = BuildConfig.SIGNAL_URL + "/v1/config";
            // Make HTTP request to test connectivity
            // Should receive "Credentials are required" response
        } catch (Exception e) {
            Log.e("ServerTest", "Connection failed", e);
        }
    }
}
```

## Build and Install Process

### Step 1: Clean and Build

```bash
# Clean previous builds
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Or build release APK (you'll need to set up signing)
./gradlew assembleRelease
```

### Step 2: Install on Device

```bash
# Install debug version
adb install app/build/outputs/apk/debug/app-debug.apk

# Or install release version
adb install app/build/outputs/apk/release/app-release.apk
```

## Testing Your Configuration

### Step 1: Basic Connectivity Test

1. **Open the app**
2. **Check logs** for connection attempts:
   ```bash
   adb logcat | grep -i signal
   ```
3. **Look for your server URLs** in the logs

### Step 2: Registration Process

1. **Start registration** with any phone number
2. **Use verification code**: Any string (e.g., "123456")
3. **Check server logs**:
   ```bash
   tail -f /root/Signal-Server/signal-test-server.log | grep -i registration
   ```

### Step 3: Message Testing

Once registered:
1. **Try sending messages** between accounts
2. **Check WebSocket connection**: Should connect to `wss://ws.testers.fun`
3. **Monitor server logs** for API calls

## Troubleshooting Common Issues

### 1. Certificate Errors

**Error**: `javax.net.ssl.SSLHandshakeException`

**Solution**:
- Ensure certificate pinning is disabled
- Check that your SSL certificates are valid
- Update network security config

### 2. Connection Refused

**Error**: `Connection refused` or `Unable to resolve host`

**Solution**:
- Verify your server is running: `curl https://api.testers.fun/v1/config`
- Check DNS resolution from device
- Ensure firewall allows connections

### 3. Registration Fails

**Error**: Registration doesn't complete

**Solution**:
- Check server logs for registration attempts
- Verify test server accepts any verification code
- Check phone number format

### 4. Push Notifications Not Working

**Issue**: Messages don't arrive when app is closed

**Solution**:
- For testing, disable push notifications or use polling
- Set up your own Firebase/GCM service
- Configure push endpoints in your server

## Development Tips

### 1. Debug Builds vs Release

- Use debug builds for development (easier debugging)
- Certificate pinning bypass works better in debug
- Enable verbose logging in debug builds

### 2. Network Debugging

Add network interceptors to see all HTTP traffic:

```java
// Add to OkHttp client builder
.addInterceptor(new HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.BODY))
```

### 3. Server Endpoint Testing

Create a test activity to verify each endpoint:

```java
// Test various endpoints
GET /v1/config
GET /v1/accounts/whoami  
POST /v1/accounts/verify/{code}
```

### 4. WebSocket Testing

Monitor WebSocket connections:

```bash
# On server side
grep -i websocket /root/Signal-Server/signal-test-server.log

# Check if WebSocket port is accessible
curl -v wss://ws.testers.fun
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Certificate Pinning Disabled**: Your app will accept any valid SSL certificate
2. **Test Server**: Uses stubbed services, not production-ready
3. **No Push Security**: Push notifications might not be encrypted
4. **Local Network**: Ensure your server is properly secured

## Quick Reference

### Key Files to Modify
```
app/build.gradle                          - Server URLs, cert pinning
app/src/main/res/xml/network_security_config.xml - SSL configuration  
ApplicationDependencies.java              - Dependency injection
Any certificate pinning code              - Disable pinning
Constants.java or Config.java             - URL constants
```

### Build Commands
```bash
./gradlew clean assembleDebug              # Build debug APK
adb install app/build/outputs/apk/debug/app-debug.apk  # Install
adb logcat | grep -i signal                # View logs
```

### Server URLs to Use
```
API: https://api.testers.fun
WebSocket: wss://ws.testers.fun
CDN: https://signal.testers.fun (or API server)
```

### Test Registration
```
Phone: Any valid format (e.g., +1234567890)
Verification Code: Any string (e.g., "123456")
```

This configuration allows your Android app to communicate with your custom Signal Server for testing and development purposes.