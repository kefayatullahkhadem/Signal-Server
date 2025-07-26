# Signal Server Access Guide

## Server Details and Client Connection

Based on the Signal Server configuration and codebase analysis, here's how to access and connect to your local Signal Server.

## Default Server Configuration

### Ports and Endpoints

From the test configuration (`service/src/test/resources/config/test.yml`), the Signal Server uses these key ports:

- **WebSocket Port**: `8444` (for real-time messaging)
- **Direct Port**: `8445` (for direct connections)
- **gRPC Services**: Various endpoints for API calls
- **Standard HTTP/HTTPS**: Dropwizard default ports (8080/8443)

### Key Server Endpoints

The Signal Server exposes several API endpoints:

#### REST API Endpoints
- `/v2/keys` - Key management (prekeys, signed keys)
- `/v2/config` - Remote configuration
- `/v1/accounts` - Account management
- `/v1/messages` - Message sending/receiving
- `/v1/profile` - User profiles
- `/v1/backup` - Backup services
- `/v1/registration` - Account registration

#### gRPC Services
- Chat service for real-time messaging
- Key management service
- Profile service
- Backup service
- Device management

## Connecting Android Signal App to Your Server

### ⚠️ Important Limitations

**The official Signal Android app cannot directly connect to a custom server** because:

1. **Hardcoded Server URLs**: The app has hardcoded URLs pointing to Signal's production servers
2. **Certificate Pinning**: Uses specific SSL certificates for Signal's servers
3. **API Keys**: Contains production API keys and secrets
4. **Service Configuration**: Configured for Signal's specific infrastructure

### Options for Testing Your Server

#### Option 1: Use Signal's Development/Testing Tools
Signal provides testing tools and libraries:
- **libsignal**: Core cryptographic library
- **Signal Protocol**: For implementing the Signal protocol
- **Testing utilities**: Available in the codebase

#### Option 2: Build a Custom Client
Create a simple client application that can:

```java
// Example client connection
String serverUrl = "http://localhost:8080";
String websocketUrl = "ws://localhost:8444";

// Register account
POST /v1/accounts/request_verification_code
{
  "number": "+1234567890",
  "transport": "sms"
}

// Verify registration
PUT /v1/accounts/code/{verification_code}

// Connect to WebSocket for real-time messaging
WebSocket connection to ws://localhost:8444
```

#### Option 3: Use Testing Endpoints

For development/testing, your server supports:

```bash
# Test registration (no real phone verification needed)
curl -X POST http://localhost:8080/v2/accounts/request_verification_code \
  -H "Content-Type: application/json" \
  -d '{"number": "+15551234567", "transport": "sms"}'

# In test mode, use: "noop.noop.registration.noop" as captcha
# Any string works for phone verification
```

### Running the Server for Client Testing

#### Method 1: Basic Server Start (without Docker)

Since Docker tests are failing, start the server in a simpler mode:

```bash
# Set environment variables
export JAVA_HOME=/opt/jdk-24.0.2
export PATH=$JAVA_HOME/bin:$PATH

# Build without tests
./mvnw clean package -DskipTests=true

# Run the server directly
java -jar service/target/TextSecureServer-*.jar server service/config/sample.yml
```

#### Method 2: Using Maven with Local Services

Modify the test configuration to use local Redis instead of Docker:

```yaml
# In test.yml, change Redis config from:
cacheCluster:
  type: local
# To use actual local Redis:
cacheCluster:
  configurationUri: redis://localhost:6379/
```

### Server Configuration for Client Access

#### 1. Basic HTTP Configuration
```yaml
server:
  applicationConnectors:
    - type: http
      port: 8080
  adminConnectors:
    - type: http
      port: 8081
```

#### 2. WebSocket Configuration
```yaml
noiseTunnel:
  webSocketPort: 8444
  directPort: 8445
```

#### 3. Test Mode Settings
```yaml
# For testing without real services
registrationService:
  type: stub  # No real phone verification

dynamoDbClient:
  type: local  # Local DynamoDB

cacheCluster:
  type: local  # Local Redis
```

## Testing Your Server

### 1. Health Check
```bash
curl http://localhost:8081/healthcheck
```

### 2. Basic API Test
```bash
# Test configuration endpoint
curl http://localhost:8080/v1/config
```

### 3. WebSocket Connection Test
```javascript
// Simple WebSocket test
const ws = new WebSocket('ws://localhost:8444');
ws.onopen = () => console.log('Connected to Signal Server');
ws.onmessage = (event) => console.log('Received:', event.data);
```

## Creating a Custom Client

### Minimal Signal Client Example

```java
public class SimpleSignalClient {
    private final String serverUrl;
    private final String websocketUrl;
    
    public SimpleSignalClient(String serverUrl, String websocketUrl) {
        this.serverUrl = serverUrl;
        this.websocketUrl = websocketUrl;
    }
    
    public void register(String phoneNumber) {
        // Send registration request
        // Handle verification code
        // Complete registration
    }
    
    public void sendMessage(String recipient, String message) {
        // Encrypt message using Signal Protocol
        // Send via REST API or WebSocket
    }
    
    public void connectWebSocket() {
        // Establish WebSocket connection for real-time messaging
    }
}
```

## Troubleshooting

### Common Issues

1. **Docker Errors**: Skip Docker-dependent tests with `-DskipTests=true`
2. **Port Conflicts**: Check if ports 8080, 8444, 8445 are available
3. **Redis Connection**: Ensure Redis is running on localhost:6379
4. **FoundationDB**: May need to install FoundationDB server for full functionality

### Docker Alternative

If you want to run the full test suite, install Docker:

```bash
# Install Docker on Ubuntu 22
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Logout and login again, then retry tests
```

## Next Steps

1. **Start Simple**: Begin with basic HTTP API testing
2. **Build Custom Client**: Create a minimal client for your use case
3. **Study Protocol**: Review Signal Protocol documentation
4. **Extend Functionality**: Add features as needed for your application

## Important Security Notes

- This setup is for **development/testing only**
- Don't use in production without proper security configuration
- Signal's production infrastructure includes many security layers not present in local testing
- Always use HTTPS/WSS in production environments