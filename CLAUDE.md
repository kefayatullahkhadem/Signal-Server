# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

Signal-Server is a Java Maven project using JDK 24 and requires FoundationDB.

### Common Maven Commands
- **Build and test**: `./mvnw clean verify` - Runs full test suite including integration tests
- **Quick build**: `./mvnw clean test` - Runs unit tests only
- **Test server**: `./mvnw integration-test -Ptest-server` - Runs test server with stubbed external services
- **Prepare package**: `./mvnw clean prepare-package -DskipTests=true` - Build without tests

### Testing Notes
- Full test suite requires FoundationDB service running
- Test server accepts `noop.noop.registration.noop` for captcha and any string for phone verification
- Integration tests are separate from unit tests and run with `verify` goal

## Architecture Overview

### Multi-Module Structure
- **service/**: Main server application with REST controllers, gRPC services, and business logic
- **api-doc/**: OpenAPI documentation generation
- **integration-tests/**: End-to-end integration tests
- **websocket-resources/**: WebSocket protocol handling
- **spam-filter/**: Optional spam filtering module (conditionally included)

### Key Technologies
- **Dropwizard 4.x**: Web framework for REST APIs and configuration
- **gRPC with Protocol Buffers**: For service communication
- **FoundationDB**: Primary database (required dependency)
- **Redis**: Caching and session storage
- **AWS SDK**: Cloud services integration
- **Netty**: Networking and async I/O

### Core Components

#### Main Service Classes
- `WhisperServerService`: Main application entry point
- `WhisperServerConfiguration`: Configuration binding
- Controllers in `controllers/` package handle REST endpoints
- gRPC services in `grpc/` package

#### Key Business Domains
- **Authentication**: Account/device auth, registration locks, challenge flows
- **Messaging**: Message routing, delivery, multi-recipient handling
- **Profiles**: User profiles, badges, avatars
- **Keys**: Pre-keys, signed keys, identity key management
- **Backup**: Account backup and restore functionality
- **Payments**: Donations, subscriptions via Stripe/Braintree

#### Data Layer
- **FoundationDB**: Primary persistent storage
- **Redis**: Caching, rate limiting, presence
- **DynamoDB**: Some auxiliary data storage
- **S3/GCP**: Attachment and media storage

### Configuration
- Main config: `service/config/sample.yml`
- Secrets: `service/config/sample-secrets-bundle.yml`
- Test config: `service/src/test/resources/config/test.yml`

### Protocol Definitions
- `.proto` files in `service/src/main/proto/` define gRPC services
- Signal chat protocol definitions in `service/src/main/proto/org/signal/chat/`

## Development Notes

### Running Locally
The test server mode provides a development environment with external dependencies stubbed out. Use the test configuration files as templates for local development.

### Code Organization
- Controllers follow RESTful patterns with Dropwizard annotations
- Business logic is typically in service classes and managers
- Database access through dedicated DAO/repository classes
- Configuration classes use Jackson for YAML binding

### Dependencies
- All version management is centralized in the root `pom.xml`
- FoundationDB client library must be installed on the host system
- Docker images are used for testing dependencies (Redis, DynamoDB)