---
description: Provider Abstraction Layer for Multi-Cloud Sandbox Management
---

# Provider Abstraction Design

## Overview

This document describes the design for a provider abstraction layer that enables ce-orchestrator to manage sandboxes across different providers (Local Docker, Aliyun ECS, AWS, Google Cloud, etc.) with a unified API.

## Goals

1. **Provider Agnostic**: Support multiple cloud providers through a unified interface
2. **Extensibility**: Easy to add new providers by implementing the `IProvider` interface
3. **Compatibility**: Maximize reuse of existing Local Docker implementation
4. **AI-First**: Designed for AI Agent control via API, not pre-programmed orchestration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ce-orchestrator                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           API Controllers (Existing)                    │   │
│  │  ContainerController, WorkflowController, ...           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │       RemoteSandboxController (NEW)                     │   │
│  │  • POST /api/remote-sandboxes/:id/start                 │   │
│  │  • POST /api/remote-sandboxes/:id/stop                  │   │
│  │  • GET  /api/remote-sandboxes                           │   │
│  │  • POST /api/remote-sandboxes/:id/exec                  │   │
│  │  • POST /api/remote-sandboxes/:id/upload               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         ProviderManager (NEW)                           │   │
│  │  • Load provider configurations                         │   │
│  │  • Instantiate provider instances                       │   │
│  │  • Route operations to correct provider                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  ┌──────────────────┬──────────────────┬──────────────────┐   │
│  │  LocalDocker     │  AliyunProvider  │  AWSProvider     │   │
│  │  Provider        │  (Future)        │  (Future)        │   │
│  └──────────────────┴──────────────────┴──────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
repos/ce-orchestrator/
├── src/
│   ├── providers/                    # NEW: Provider Layer
│   │   ├── types.ts                  # Unified interface definitions
│   │   ├── ProviderManager.ts        # Provider manager
│   │   ├── base/
│   │   │   └── BaseProvider.ts       # Abstract base class (with retry logic)
│   │   ├── local-docker/
│   │   │   └── LocalDockerProvider.ts # Reuses existing docker.ts
│   │   ├── aliyun/
│   │   │   └── AliyunProvider.ts     # SSH + Docker
│   │   └── factory.ts                # Provider factory
│   │
│   ├── services/
│   │   ├── docker.ts                 # PRESERVED! As LocalDockerProvider implementation
│   │   └── ...
│   │
│   ├── controllers/
│   │   └── RemoteSandboxController.ts # NEW: Remote sandbox API
│   │
│   ├── config/
│   │   └── providers.yaml            # Provider configuration file
│   │
│   └── utils/
│       ├── ssh-client.ts             # NEW: SSH connection utility
│       └── retry.ts                  # NEW: Smart retry logic
```

## Provider Interface

```typescript
// src/providers/types.ts

interface Sandbox {
  id: string;
  name: string;
  status: 'running' | 'stopped' | 'error';
  provider: string;
  containerName?: string;
  createdAt: Date;
}

interface ProviderConfig {
  type: 'local-docker' | 'aliyun' | 'aws' | 'gcp';
  [key: string]: any; // Provider-specific configuration
}

interface IProvider {
  // Basic operations
  listSandboxes(): Promise<Sandbox[]>;
  startSandbox(id: string): Promise<void>;
  stopSandbox(id: string): Promise<void>;
  restartSandbox(id: string): Promise<void>;
  getSandboxStatus(id: string): Promise<SandboxStatus>;
  
  // Advanced operations
  execCommand(id: string, command: string): Promise<ExecResult>;
  uploadFile(id: string, localPath: string, remotePath: string): Promise<void>;
  downloadFile(id: string, remotePath: string, localPath: string): Promise<void>;
  getLogs(id: string, tail?: number): Promise<string>;
  deleteSandbox(id: string): Promise<void>;
}

interface ExecResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

interface SandboxStatus {
  status: 'running' | 'stopped' | 'error';
  cpu?: number;
  memory?: number;
  uptime?: number;
}
```

## Configuration Format

```yaml
# config/providers.yaml

providers:
  # Local Docker Provider (default)
  local-docker:
    type: local-docker
    dockerNetwork: kai-net
    baseRoot: ~/KaiBase

  # Aliyun ECS Provider
  aliyun-prod:
    type: aliyun
    host: ecs.your-instance.com
    port: 22
    username: root
    auth:
      type: privateKey
      keyPath: ~/.ssh/aliyun.pem
    dockerNetwork: kai-net
    baseRoot: /workspace

  # Future AWS Provider
  aws-prod:
    type: aws
    region: us-east-1
    accessKeyId: ${AWS_ACCESS_KEY_ID}
    secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
    instanceId: i-xxxxxxxxx

sandboxes:
  # Local development sandbox
  local-dev:
    provider: local-docker
    container: flexy-local-dev
    description: Local development environment

  # Commercial products sandbox
  commercial-products:
    provider: aliyun-prod
    container: flexy-commercial-products
    description: Commercial product line
    repos:
      - flexyclaw
      - richmenu-editor

  # E-commerce platform sandbox
  ecommerce:
    provider: aliyun-prod
    container: flexy-ecommerce
    description: E-commerce platform
    repos:
      - weiwei-car-business
      - bonbalayelo

  # AI infrastructure sandbox
  infra-tools:
    provider: aliyun-prod
    container: flexy-infra-tools
    description: AI infrastructure + Studio tools
    repos:
      - edge-filesystem
      - edge-hippo
      - karo-platform
      - threads-mcp
      - flexy-sandbox
      - chromium-ai-sandbox
      - cloudflare-line-liff
      - cloudflare-email-flows
```

## API Design

```
# Remote Sandbox Management APIs
# Base path: /api/remote-sandboxes

GET    /api/remote-sandboxes
       → List all sandboxes (across all providers)

POST   /api/remote-sandboxes/:id/start
       → Start sandbox

POST   /api/remote-sandboxes/:id/stop
       → Stop sandbox

POST   /api/remote-sandboxes/:id/restart
       → Restart sandbox

GET    /api/remote-sandboxes/:id/status
       → Get sandbox status

GET    /api/remote-sandboxes/:id/logs?tail=100
       → Get sandbox logs

POST   /api/remote-sandboxes/:id/exec
       → Execute command in sandbox
       Body: { command: string; timeout?: number }

POST   /api/remote-sandboxes/:id/upload
       → Upload file to sandbox
       Body: FormData { localPath: string; remotePath: string }

POST   /api/remote-sandboxes/:id/download
       → Download file from sandbox
       Body: { remotePath: string; localPath: string }

DELETE /api/remote-sandboxes/:id
       → Delete sandbox

# Provider Management

GET    /api/providers
       → List all providers

POST   /api/providers/:id/test
       → Test provider connection
```

## Error Handling & Retry Strategy

```typescript
// src/utils/retry.ts

enum ErrorType {
  NETWORK = 'network',           // Network error → retry
  TIMEOUT = 'timeout',           // Timeout → retry (limited)
  AUTH = 'auth',                 // Auth error → fail immediately
  NOT_FOUND = 'not_found',       // Not found → fail immediately
  PERMISSION = 'permission',     // Permission error → fail immediately
  UNKNOWN = 'unknown'            // Unknown → retry (limited)
}

interface RetryConfig {
  maxRetries: number;            // Maximum retry attempts
  initialDelay: number;          // Initial delay (ms)
  maxDelay: number;              // Maximum delay (ms)
  backoffMultiplier: number;     // Backoff multiplier
  retryableErrors: ErrorType[];  // Retryable error types
}

// Default configuration
const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxRetries: 5,
  initialDelay: 1000,
  maxDelay: 30000,
  backoffMultiplier: 2,
  retryableErrors: [ErrorType.NETWORK, ErrorType.TIMEOUT, ErrorType.UNKNOWN]
};
```

## Implementation Phases

```
Phase 1: Foundation (1-2 days)
├── Create Provider interface and base classes
├── Implement ProviderManager and factory
├── Smart retry logic
└── Configuration file loader

Phase 2: LocalDockerProvider (1 day)
├── Reuse existing docker.ts service
├── Implement IProvider interface
└── Local testing

Phase 3: AliyunProvider (2-3 days)
├── SSH connection management
├── Remote Docker command execution
├── File transfer (SFTP)
└── Cloud testing

Phase 4: API & Integration (1-2 days)
├── RemoteSandboxController
├── TSOA route generation
├── API documentation update
└── Frontend integration

Phase 5: Testing & Documentation (1 day)
├── Unit tests
├── Integration tests
├── Usage documentation
└── Release preparation
```

## Design Decisions

### Why Smart Retry (Option D)?
Network operations to cloud providers are inherently unreliable. Smart retry distinguishes between recoverable errors (network, timeout) and fatal errors (auth, permission), providing both resilience and fast failure when appropriate.

### Why Configuration File (Option B)?
Environment variables become unwieldy with multiple providers. A YAML configuration file is more organized, supports encryption for sensitive data, and can be version-controlled (with secrets encrypted or in env vars).

### Why Sandbox-Level Mapping (Option A)?
Each sandbox has a clear relationship to its provider, making the API more intuitive. The AI Agent can simply reference `commercial-products` without knowing which provider it uses.

### Why Unified Interface (Option A)?
All major cloud ECS providers offer similar capabilities (SSH + Linux + Docker). A unified interface keeps the API simple and consistent, while provider-specific details are handled in implementation.

## Dependencies

### New Dependencies
```json
{
  "ssh2-sftp-client": "^10.0.0",
  "node-pty": "^1.0.0",
  "js-yaml": "^4.1.0"
}
```

### Existing Dependencies (Reused)
- `dockerode` - Docker API client (existing)
- `tsoa` - API framework (existing)

## Security Considerations

1. **SSH Keys**: Private keys should be stored securely, never in the repository
2. **Configuration**: Support environment variable substitution for sensitive values
3. **Network**: All cloud connections should use SSH key authentication, not passwords
4. **File Access**: Validate all paths to prevent directory traversal attacks
5. **Command Injection**: Sanitize all commands executed on remote systems

## Testing Strategy

1. **Unit Tests**: Test each provider independently with mocks
2. **Integration Tests**: Test against real Local Docker
3. **Contract Tests**: Verify API conforms to OpenAPI spec
4. **Manual Tests**: Test Aliyun provider with real ECS instance
