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