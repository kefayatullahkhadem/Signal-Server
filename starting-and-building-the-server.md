# Signal Server - Starting and Building Guide

This guide documents the complete process of building and starting the Signal Server, including all issues encountered and their solutions.

## Prerequisites

- Ubuntu 22.04 LTS
- JDK 24 installed at `/opt/jdk-24.0.2`
- FoundationDB 7.3.62 (client and server)
- Redis server
- Docker and Docker Compose
- Maven Wrapper (`mvnw`)

## Issues Encountered and Solutions

### 1. Maven Dependency Resolution Issues

**Problem**: When trying to start the server directly, Maven couldn't resolve the `websocket-resources` dependency:
```
Could not find artifact org.whispersystems.textsecure:websocket-resources:jar:0.0.0-dirty-SNAPSHOT
```

**Cause**: The project has multiple modules that need to be built and installed in the correct order. The `service` module depends on `websocket-resources`, but it wasn't installed in the local Maven repository.

**Solution**: Build and install all dependencies first:
```bash
export JAVA_HOME=/opt/jdk-24.0.2
export PATH=$JAVA_HOME/bin:$PATH
./mvnw install -DskipTests=true
```

### 2. Test Server Profile Complexity

**Problem**: Using `./mvnw integration-test -Ptest-server` would run all tests, taking 10+ minutes and sometimes failing on performance tests.

**Cause**: The `test-server` profile is designed for integration testing, not just starting a development server.

**Solution**: Use the `exec:java` goal to start the server directly without running tests:
```bash
./mvnw exec:java -pl service \
  -Dexec.mainClass="org.whispersystems.textsecuregcm.WhisperServerService" \
  -Dexec.args="server service/src/test/resources/config/test.yml" \
  -DskipTests=true
```

### 3. JAR File Missing Main Manifest

**Problem**: Trying to run the built JAR directly failed:
```
no main manifest attribute, in service/target/TextSecureServer-0.0.0-dirty-SNAPSHOT.jar
```

**Cause**: The JAR built by Maven doesn't include a proper manifest for direct execution. It's designed to be used with the exec plugin or application runner.

**Solution**: Use Maven's exec plugin instead of trying to run the JAR directly.

### 4. Server Starting but Not Accessible

**Problem**: Nginx showed "502 Bad Gateway" even when the server appeared to be starting.

**Cause**: The server wasn't actually listening on the expected ports (8080 for API, 8444 for WebSocket) due to startup failures or configuration issues.

**Solution**: 
1. Ensure all dependencies are properly built and installed
2. Use proper background execution with logging
3. Wait sufficient time for server startup (30+ seconds)
4. Verify ports are actually listening

## Step-by-Step Build and Start Process

### Step 1: Environment Setup

```bash
# Set Java environment
export JAVA_HOME=/opt/jdk-24.0.2
export PATH=$JAVA_HOME/bin:$PATH

# Navigate to Signal Server directory
cd /root/Signal-Server
```

### Step 2: Clean and Build All Dependencies

```bash
# Clean previous builds and install all modules
./mvnw clean install -DskipTests=true
```

**Expected Output**: All 5 modules should build successfully:
- TextSecureServer (pom)
- websocket-resources (jar)
- service (jar)
- api-doc (jar)
- integration-tests (jar)

**Time**: ~1-2 minutes

### Step 3: Create Startup Script

Create `start-test-server.sh`:

```bash
#!/bin/bash

# Signal Server Test Startup Script
export JAVA_HOME=/opt/jdk-24.0.2
export PATH=$JAVA_HOME/bin:$PATH

cd /root/Signal-Server

echo "Starting Signal Test Server in background..."

# Start the server in background without tests
nohup ./mvnw exec:java -pl service \
  -Dexec.mainClass="org.whispersystems.textsecuregcm.WhisperServerService" \
  -Dexec.args="server service/src/test/resources/config/test.yml" \
  -q > signal-test-server.log 2>&1 &

SERVER_PID=$!
echo "Signal Server started with PID: $SERVER_PID"
echo $SERVER_PID > signal-server.pid

echo "Waiting 30 seconds for server to start..."
sleep 30

# Check if server is responding
if curl -s http://localhost:8080/v1/config > /dev/null; then
    echo "✅ Signal Server is running on http://localhost:8080"
    echo "✅ Available at https://signal.testers.fun"
    echo "✅ API at https://api.testers.fun"
    echo "✅ WebSocket at wss://ws.testers.fun"
else
    echo "❌ Server not responding on port 8080"
    echo "Check logs: tail -f signal-test-server.log"
fi
```

```bash
# Make script executable
chmod +x start-test-server.sh
```

### Step 4: Start the Server

```bash
# Run the startup script
./start-test-server.sh
```

**Expected Output**:
```
Starting Signal Test Server in background...
Signal Server started with PID: 78373
Waiting 30 seconds for server to start...
✅ Signal Server is running on http://localhost:8080
✅ Available at https://signal.testers.fun
✅ API at https://api.testers.fun
✅ WebSocket at wss://ws.testers.fun
```

### Step 5: Verify Server is Running

```bash
# Check if ports are listening
ss -tlnp | grep -E ":(8080|8444)"

# Test API endpoint
curl -s http://localhost:8080/v1/config

# Test HTTPS domain
curl -s https://signal.testers.fun/v1/config
```

**Expected Response**: "Credentials are required to access this resource." (This confirms the server is working)

## Server Management Commands

### Start Server
```bash
./start-test-server.sh
```

### Check Server Status
```bash
# Check if process is running
ps aux | grep WhisperServerService | grep -v grep

# Check server logs
tail -f signal-test-server.log

# Test server response
curl -s http://localhost:8080/v1/config
```

### Stop Server
```bash
# Using PID file
kill $(cat signal-server.pid)

# Or find and kill manually
pkill -f WhisperServerService
```

### Monitor Logs
```bash
# Follow real-time logs
tail -f signal-test-server.log

# Check for errors
grep -i error signal-test-server.log

# Check startup sequence
grep -E "(Started|INFO.*Server)" signal-test-server.log
```

## Configuration Files

### Main Test Configuration
- **File**: `service/src/test/resources/config/test.yml`
- **Purpose**: Test server configuration with stubbed external services
- **Ports**: 8080 (API), 8444 (WebSocket), 8081 (Admin)

### Key Configuration Features in Test Mode
- **Stubbed external services**: No real AWS/GCP dependencies
- **Captcha**: Accepts `noop.noop.registration.noop`
- **Phone verification**: Accepts any string
- **Database**: Uses local FoundationDB and Redis
- **Logging**: Console output with INFO level

## Troubleshooting Common Issues

### 1. "Could not resolve dependencies" Error

**Solution**:
```bash
# Clean and rebuild everything
./mvnw clean install -DskipTests=true
```

### 2. Server Starts but Nginx Shows 502

**Solution**:
```bash
# Check if server is actually listening
ss -tlnp | grep 8080

# Check server logs for startup errors
tail -50 signal-test-server.log

# Restart server if needed
kill $(cat signal-server.pid)
./start-test-server.sh
```

### 3. Server Startup Takes Too Long

**Causes**:
- First-time startup downloads dependencies
- FoundationDB or Redis connection issues
- Configuration validation problems

**Solution**:
```bash
# Check service dependencies
sudo systemctl status foundationdb redis-server

# Check for configuration errors
./mvnw exec:java -pl service -Dexec.mainClass="org.whispersystems.textsecuregcm.WhisperServerService" -Dexec.args="check service/src/test/resources/config/test.yml"
```

### 4. Out of Memory Errors

**Solution**:
```bash
# Increase JVM memory in startup script
export MAVEN_OPTS="-Xmx2g -Xms1g"
./start-test-server.sh
```

## Performance Notes

- **First build**: 1-2 minutes (downloads dependencies)
- **Subsequent builds**: 30-60 seconds (if no code changes)
- **Server startup**: 20-30 seconds
- **Memory usage**: ~500MB-1GB RAM

## Quick Reference

### Essential Commands
```bash
# Build everything
./mvnw clean install -DskipTests=true

# Start server
./start-test-server.sh

# Check status
curl -s http://localhost:8080/v1/config

# Stop server
kill $(cat signal-server.pid)

# View logs
tail -f signal-test-server.log
```

### Server URLs
- **Local API**: `http://localhost:8080`
- **Local Admin**: `http://localhost:8081`
- **Public API**: `https://signal.testers.fun`
- **Public API Alt**: `https://api.testers.fun`
- **WebSocket**: `wss://ws.testers.fun`

## Development Workflow

1. **Make code changes**
2. **Rebuild**: `./mvnw install -pl service -DskipTests=true`
3. **Restart server**: `kill $(cat signal-server.pid) && ./start-test-server.sh`
4. **Test changes**: Use API calls or Android client

This approach ensures fast development cycles without running the full test suite each time.