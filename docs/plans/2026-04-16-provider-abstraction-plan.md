# Provider Abstraction Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a provider abstraction layer that enables ce-orchestrator to manage sandboxes across multiple cloud providers (Local Docker, Aliyun ECS) with a unified API.

**Architecture:** 
- Provider interface pattern with factory for extensibility
- ProviderManager routes operations to correct provider instance
- Smart retry logic with exponential backoff for network operations
- Configuration-driven provider and sandbox registration
- TSOA-based REST API for remote sandbox management

**Tech Stack:** TypeScript, Node.js, Express, TSOA, Dockerode, SSH2, YAML

---

## File Structure

```
repos/ce-orchestrator/
├── src/
│   ├── providers/                    # NEW: Provider Layer
│   │   ├── types.ts                  # Type definitions (interfaces, enums, errors)
│   │   ├── base/
│   │   │   ├── BaseProvider.ts       # Abstract base class with retry logic
│   │   │   └── BaseProvider.test.ts  # Unit tests
│   │   ├── factory.ts                # Provider factory + tests
│   │   ├── local-docker/
│   │   │   ├── LocalDockerProvider.ts # Local Docker implementation
│   │   │   └── LocalDockerProvider.test.ts
│   │   ├── aliyun/
│   │   │   ├── AliyunProvider.ts     # Aliyun ECS implementation
│   │   │   └── AliyunProvider.test.ts
│   │   └── ProviderManager.ts        # Provider manager + tests
│   ├── controllers/
│   │   └── RemoteSandboxController.ts # NEW: TSOA controller
│   ├── utils/
│   │   ├── ssh-client.ts             # SSH connection wrapper + tests
│   │   └── retry.ts                  # Smart retry logic + tests
│   └── config/
│       └── providers.schema.yaml     # Configuration schema
├── config/
│   └── providers.yaml                # Provider configuration (user-edited)
├── tests/
│   ├── providers/                    # Integration tests
│   │   ├── ProviderManager.test.ts
│   │   └── providers.fixture.ts      # Test fixtures
│   └── api/
│       └── RemoteSandboxController.test.ts
└── package.json                      # Add new dependencies
```

---

## Phase 1: Foundation - Types, Retry, and Base Provider

### Task 1: Add New Dependencies

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Add dependencies to package.json**

```json
{
  "dependencies": {
    "ssh2-sftp-client": "^10.0.0",
    "ssh2": "^1.15.0",
    "js-yaml": "^4.1.0"
  },
  "devDependencies": {
    "@types/js-yaml": "^4.0.9"
  }
}
```

- [ ] **Step 2: Install dependencies**

Run: `cd repos/ce-orchestrator && pnpm install`

Expected: Dependencies installed successfully

- [ ] **Step 3: Commit**

```bash
cd repos/ce-orchestrator
git add package.json pnpm-lock.yaml
git commit -m "feat: add provider abstraction dependencies

Add ssh2, ssh2-sftp-client, and js-yaml for multi-cloud
provider support.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Create Provider Types

**Files:**
- Create: `repos/ce-orchestrator/src/providers/types.ts`

- [ ] **Step 1: Create types file with all interfaces**

```typescript
// src/providers/types.ts

/**
 * Sandbox status enum
 */
export enum SandboxStatus {
  RUNNING = 'running',
  STOPPED = 'stopped',
  ERROR = 'error'
}

/**
 * Sandbox information
 */
export interface Sandbox {
  id: string;
  name: string;
  status: SandboxStatus;
  provider: string;
  containerName?: string;
  createdAt: Date;
  description?: string;
  repos?: string[];
}

/**
 * Detailed sandbox status with resource usage
 */
export interface SandboxStatusDetail {
  status: SandboxStatus;
  cpu?: number;
  memory?: number;
  uptime?: number;
  ip?: string;
}

/**
 * Command execution result
 */
export interface ExecResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

/**
 * Provider type enum
 */
export enum ProviderType {
  LOCAL_DOCKER = 'local-docker',
  ALIYUN = 'aliyun',
  AWS = 'aws',
  GCP = 'gcp'
}

/**
 * Base provider configuration
 */
export interface BaseProviderConfig {
  type: ProviderType;
}

/**
 * Local Docker provider configuration
 */
export interface LocalDockerProviderConfig extends BaseProviderConfig {
  type: ProviderType.LOCAL_DOCKER;
  dockerNetwork: string;
  baseRoot: string;
}

/**
 * SSH authentication types
 */
export type SSHAuth = 
  | { type: 'privateKey'; keyPath: string; passphrase?: string }
  | { type: 'password'; password: string };

/**
 * Aliyun ECS provider configuration
 */
export interface AliyunProviderConfig extends BaseProviderConfig {
  type: ProviderType.ALIYUN;
  host: string;
  port: number;
  username: string;
  auth: SSHAuth;
  dockerNetwork: string;
  baseRoot: string;
}

/**
 * Union type for all provider configs
 */
export type ProviderConfig = 
  | LocalDockerProviderConfig
  | AliyunProviderConfig;

/**
 * Sandbox configuration
 */
export interface SandboxConfig {
  id: string;
  provider: string;
  container: string;
  description?: string;
  repos?: string[];
}

/**
 * Full configuration file structure
 */
export interface ProvidersConfiguration {
  providers: Record<string, ProviderConfig>;
  sandboxes: Record<string, SandboxConfig>;
}

/**
 * Provider information
 */
export interface ProviderInfo {
  id: string;
  type: ProviderType;
  status: 'connected' | 'disconnected' | 'error';
  error?: string;
}
```

- [ ] **Step 2: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/types.ts
git commit -m "feat: add provider type definitions

Define interfaces and types for multi-cloud provider abstraction
including Sandbox, ProviderConfig, and authentication types.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Create Smart Retry Logic

**Files:**
- Create: `repos/ce-orchestrator/src/utils/retry.ts`
- Create: `repos/ce-orchestrator/src/utils/retry.test.ts`

- [ ] **Step 1: Write the retry utility test**

```typescript
// src/utils/retry.test.ts

import { describe, it, expect, vi } from 'vitest';
import { SmartRetry, ErrorType, RetryExhaustedError, RetryConfig } from './retry';

describe('SmartRetry', () => {
  describe('classifyError', () => {
    it('should classify ECONNREFUSED as NETWORK error', () => {
      const error = new Error('Connection refused');
      (error as any).code = 'ECONNREFUSED';
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.NETWORK);
    });

    it('should classify ENOTFOUND as NETWORK error', () => {
      const error = new Error('Not found');
      (error as any).code = 'ENOTFOUND';
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.NETWORK);
    });

    it('should classify ETIMEDOUT as TIMEOUT error', () => {
      const error = new Error('Timeout');
      (error as any).code = 'ETIMEDOUT';
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.TIMEOUT);
    });

    it('should classify authentication error as AUTH error', () => {
      const error = new Error('authentication failed');
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.AUTH);
    });

    it('should classify Unauthorized as AUTH error', () => {
      const error = new Error('Unauthorized');
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.AUTH);
    });

    it('should classify 401 as AUTH error', () => {
      const error = new Error('Not authorized');
      (error as any).code = 401;
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.AUTH);
    });

    it('should classify not found as NOT_FOUND error', () => {
      const error = new Error('container not found');
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.NOT_FOUND);
    });

    it('should classify 404 as NOT_FOUND error', () => {
      const error = new Error('Not found');
      (error as any).code = 404;
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.NOT_FOUND);
    });

    it('should classify permission error as PERMISSION error', () => {
      const error = new Error('permission denied');
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.PERMISSION);
    });

    it('should classify EACCES as PERMISSION error', () => {
      const error = new Error('Access denied');
      (error as any).code = 'EACCES';
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.PERMISSION);
    });

    it('should classify unknown errors as UNKNOWN', () => {
      const error = new Error('something went wrong');
      expect(SmartRetry.classifyError(error)).toBe(ErrorType.UNKNOWN);
    });
  });

  describe('execute', () => {
    it('should return result on first success', async () => {
      const fn = vi.fn().mockResolvedValue('success');
      const config: RetryConfig = {
        maxRetries: 3,
        initialDelay: 10,
        maxDelay: 100,
        backoffMultiplier: 2,
        retryableErrors: [ErrorType.NETWORK, ErrorType.TIMEOUT]
      };

      const result = await SmartRetry.execute(fn, config);
      expect(result).toBe('success');
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('should retry on retryable errors', async () => {
      const fn = vi.fn()
        .mockRejectedValueOnce(new Error('Connection refused'))
        .mockRejectedValueOnce(new Error('Connection refused'))
        .mockResolvedValue('success');
      
      (fn as any).mock.calls[0]?.[0]?.().code = 'ECONNREFUSED';

      const config: RetryConfig = {
        maxRetries: 5,
        initialDelay: 10,
        maxDelay: 100,
        backoffMultiplier: 2,
        retryableErrors: [ErrorType.NETWORK, ErrorType.TIMEOUT]
      };

      // Mock the error with code
      const error1 = new Error('Connection refused');
      (error1 as any).code = 'ECONNREFUSED';
      const error2 = new Error('Connection refused');
      (error2 as any).code = 'ECONNREFUSED';

      fn.mockRejectedValueOnce(error1)
        .mockRejectedValueOnce(error2)
        .mockResolvedValue('success');

      const result = await SmartRetry.execute(fn, config);
      expect(result).toBe('success');
      expect(fn).toHaveBeenCalledTimes(3);
    });

    it('should fail immediately on non-retryable errors', async () => {
      const authError = new Error('authentication failed');
      const fn = vi.fn().mockRejectedValue(authError);
      
      const config: RetryConfig = {
        maxRetries: 5,
        initialDelay: 10,
        maxDelay: 100,
        backoffMultiplier: 2,
        retryableErrors: [ErrorType.NETWORK, ErrorType.TIMEOUT]
      };

      await expect(SmartRetry.execute(fn, config)).rejects.toThrow(authError);
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('should throw RetryExhaustedError after max retries', async () => {
      const error = new Error('Connection refused');
      (error as any).code = 'ECONNREFUSED';
      const fn = vi.fn().mockRejectedValue(error);
      
      const config: RetryConfig = {
        maxRetries: 2,
        initialDelay: 10,
        maxDelay: 100,
        backoffMultiplier: 2,
        retryableErrors: [ErrorType.NETWORK, ErrorType.TIMEOUT]
      };

      await expect(SmartRetry.execute(fn, config)).rejects.toThrow(RetryExhaustedError);
      expect(fn).toHaveBeenCalledTimes(3); // initial + 2 retries
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- retry.test.ts`

Expected: FAIL with "SmartRetry is not defined"

- [ ] **Step 3: Implement retry utility**

```typescript
// src/utils/retry.ts

/**
 * Error types for retry classification
 */
export enum ErrorType {
  NETWORK = 'network',
  TIMEOUT = 'timeout',
  AUTH = 'auth',
  NOT_FOUND = 'not_found',
  PERMISSION = 'permission',
  UNKNOWN = 'unknown'
}

/**
 * Retry configuration
 */
export interface RetryConfig {
  maxRetries: number;
  initialDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
  retryableErrors: ErrorType[];
}

/**
 * Error thrown when all retries are exhausted
 */
export class RetryExhaustedError extends Error {
  public readonly originalError: Error;

  constructor(message: string, originalError: Error) {
    super(message);
    this.name = 'RetryExhaustedError';
    this.originalError = originalError;
  }
}

/**
 * Smart retry utility with exponential backoff
 */
export class SmartRetry {
  /**
   * Execute a function with retry logic
   */
  static async execute<T>(
    fn: () => Promise<T>,
    config: RetryConfig
  ): Promise<T> {
    let lastError: Error;
    let delay = config.initialDelay;

    for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error as Error;
        const errorType = this.classifyError(error);

        // Non-retryable error, fail immediately
        if (!config.retryableErrors.includes(errorType)) {
          throw error;
        }

        // Last attempt failed, throw
        if (attempt === config.maxRetries) {
          throw new RetryExhaustedError(
            `Failed after ${attempt} attempts`,
            lastError
          );
        }

        // Wait before retry
        await this.sleep(delay);
        delay = Math.min(delay * config.backoffMultiplier, config.maxDelay);
      }
    }

    throw lastError;
  }

  /**
   * Classify error into retry type
   */
  static classifyError(error: any): ErrorType {
    const code = error.code;
    const message = error.message?.toLowerCase() || '';

    // Network errors
    if (code === 'ECONNREFUSED' || code === 'ENOTFOUND' || code === 'ECONNRESET') {
      return ErrorType.NETWORK;
    }

    // Timeout errors
    if (code === 'ETIMEDOUT' || code === 'ESOCKETTIMEDOUT' || message.includes('timeout')) {
      return ErrorType.TIMEOUT;
    }

    // Auth errors
    if (message.includes('authentication') || message.includes('unauthorized') || code === 401) {
      return ErrorType.AUTH;
    }

    // Not found errors
    if (message.includes('not found') || code === 404) {
      return ErrorType.NOT_FOUND;
    }

    // Permission errors
    if (message.includes('permission') || message.includes('denied') || code === 'EACCES' || code === 403) {
      return ErrorType.PERMISSION;
    }

    return ErrorType.UNKNOWN;
  }

  /**
   * Sleep for specified milliseconds
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Default retry configuration
 */
export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxRetries: 5,
  initialDelay: 1000,
  maxDelay: 30000,
  backoffMultiplier: 2,
  retryableErrors: [
    ErrorType.NETWORK,
    ErrorType.TIMEOUT,
    ErrorType.UNKNOWN
  ]
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- retry.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/utils/retry.ts src/utils/retry.test.ts
git commit -m "feat: add smart retry utility with exponential backoff

Implement retry logic that classifies errors and applies
exponential backoff for retryable errors (network, timeout)
while failing immediately for fatal errors (auth, permission).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Create Base Provider Class

**Files:**
- Create: `repos/ce-orchestrator/src/providers/base/BaseProvider.ts`
- Create: `repos/ce-orchestrator/src/providers/base/BaseProvider.test.ts`

- [ ] **Step 1: Write the BaseProvider test**

```typescript
// src/providers/base/BaseProvider.test.ts

import { describe, it, expect, vi } from 'vitest';
import { BaseProvider } from './BaseProvider';
import { SandboxStatus, ProviderType } from '../types';

describe('BaseProvider', () => {
  class TestProvider extends BaseProvider {
    async listSandboxes() {
      return [];
    }
    async startSandbox(id: string) {
      return;
    }
    async stopSandbox(id: string) {
      return;
    }
    async restartSandbox(id: string) {
      return;
    }
    async getSandboxStatus(id: string) {
      return { status: SandboxStatus.STOPPED };
    }
    async execCommand(id: string, command: string) {
      return { exitCode: 0, stdout: '', stderr: '' };
    }
    async uploadFile(id: string, localPath: string, remotePath: string) {
      return;
    }
    async downloadFile(id: string, remotePath: string, localPath: string) {
      return;
    }
    async getLogs(id: string, tail?: number) {
      return '';
    }
    async deleteSandbox(id: string) {
      return;
    }
  }

  describe('constructor', () => {
    it('should initialize with config and id', () => {
      const config = { type: ProviderType.LOCAL_DOCKER, dockerNetwork: 'test-net', baseRoot: '/test' };
      const provider = new TestProvider('test-provider', config);
      expect(provider.id).toBe('test-provider');
      expect(provider.config).toBe(config);
    });
  });

  describe('executeWithRetry', () => {
    it('should use default retry config', async () => {
      const config = { type: ProviderType.LOCAL_DOCKER, dockerNetwork: 'test-net', baseRoot: '/test' };
      const provider = new TestProvider('test-provider', config);
      
      let attempts = 0;
      const fn = vi.fn().mockImplementation(async () => {
        attempts++;
        if (attempts < 3) {
          const error = new Error('Connection refused');
          (error as any).code = 'ECONNREFUSED';
          throw error;
        }
        return 'success';
      });

      const result = await provider.executeWithRetry(fn);
      expect(result).toBe('success');
      expect(attempts).toBe(3);
    });

    it('should pass through custom retry config', async () => {
      const config = { type: ProviderType.LOCAL_DOCKER, dockerNetwork: 'test-net', baseRoot: '/test' };
      const provider = new TestProvider('test-provider', config);
      
      const fn = vi.fn().mockResolvedValue('success');
      const customConfig = { maxRetries: 1, initialDelay: 1, maxDelay: 10, backoffMultiplier: 1, retryableErrors: [] };

      await provider.executeWithRetry(fn, customConfig);
      expect(fn).toHaveBeenCalledTimes(1);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- BaseProvider.test.ts`

Expected: FAIL with "BaseProvider is not defined"

- [ ] **Step 3: Implement BaseProvider**

```typescript
// src/providers/base/BaseProvider.ts

import { ProviderConfig, ExecResult, SandboxStatusDetail, Sandbox } from '../types';
import { SmartRetry, RetryConfig, DEFAULT_RETRY_CONFIG } from '../../utils/retry';

/**
 * Abstract base class for all providers
 * Implements retry logic and defines common interface
 */
export abstract class BaseProvider {
  readonly id: string;
  readonly config: ProviderConfig;
  protected retryConfig: RetryConfig;

  constructor(id: string, config: ProviderConfig, retryConfig?: RetryConfig) {
    this.id = id;
    this.config = config;
    this.retryConfig = retryConfig || DEFAULT_RETRY_CONFIG;
  }

  /**
   * Execute a function with retry logic
   */
  protected async executeWithRetry<T>(fn: () => Promise<T>, customRetryConfig?: RetryConfig): Promise<T> {
    return SmartRetry.execute(fn, customRetryConfig || this.retryConfig);
  }

  // Abstract methods - must be implemented by concrete providers

  /**
   * List all sandboxes managed by this provider
   */
  abstract listSandboxes(): Promise<Sandbox[]>;

  /**
   * Start a sandbox
   */
  abstract startSandbox(id: string): Promise<void>;

  /**
   * Stop a sandbox
   */
  abstract stopSandbox(id: string): Promise<void>;

  /**
   * Restart a sandbox
   */
  abstract restartSandbox(id: string): Promise<void>;

  /**
   * Get detailed status of a sandbox
   */
  abstract getSandboxStatus(id: string): Promise<SandboxStatusDetail>;

  /**
   * Execute a command in a sandbox
   */
  abstract execCommand(id: string, command: string): Promise<ExecResult>;

  /**
   * Upload a file to a sandbox
   */
  abstract uploadFile(id: string, localPath: string, remotePath: string): Promise<void>;

  /**
   * Download a file from a sandbox
   */
  abstract downloadFile(id: string, remotePath: string, localPath: string): Promise<void>;

  /**
   * Get logs from a sandbox
   */
  abstract getLogs(id: string, tail?: number): Promise<string>;

  /**
   * Delete a sandbox
   */
  abstract deleteSandbox(id: string): Promise<void>;

  /**
   * Test if provider is connected and functional
   */
  abstract testConnection(): Promise<boolean>;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- BaseProvider.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/base/BaseProvider.ts src/providers/base/BaseProvider.test.ts
git commit -m "feat: add BaseProvider abstract class

Define abstract base class for all providers with retry logic
and common interface methods.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 2: LocalDockerProvider - Reuse Existing Docker Service

### Task 5: Create LocalDockerProvider

**Files:**
- Create: `repos/ce-orchestrator/src/providers/local-docker/LocalDockerProvider.ts`
- Create: `repos/ce-orchestrator/src/providers/local-docker/LocalDockerProvider.test.ts`

- [ ] **Step 1: Write LocalDockerProvider test**

```typescript
// src/providers/local-docker/LocalDockerProvider.test.ts

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { LocalDockerProvider } from './LocalDockerProvider';
import { ProviderType, SandboxStatus } from '../../types';
import * as dockerService from '../../../services/docker';

// Mock docker service
vi.mock('../../../services/docker', () => ({
  listContainers: vi.fn(),
  startContainer: vi.fn(),
  stopContainer: vi.fn(),
  deleteContainer: vi.fn(),
  getContainerStats: vi.fn(),
}));

describe('LocalDockerProvider', () => {
  let provider: LocalDockerProvider;
  const mockConfig = {
    type: ProviderType.LOCAL_DOCKER,
    dockerNetwork: 'kai-net',
    baseRoot: '/KaiBase'
  };

  beforeEach(() => {
    provider = new LocalDockerProvider('local-docker', mockConfig);
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('constructor', () => {
    it('should initialize with config', () => {
      expect(provider.id).toBe('local-docker');
      expect(provider.config).toEqual(mockConfig);
    });
  });

  describe('listSandboxes', () => {
    it('should return list of sandboxes', async () => {
      const mockContainers = [
        {
          id: 'abc123',
          name: 'flexy-test-container',
          status: 'running',
          folderMapping: '/local/path:/workspace',
          createdAt: '2024-01-01T00:00:00.000Z'
        }
      ];
      vi.mocked(dockerService.listContainers).mockResolvedValue(mockContainers as any);

      const sandboxes = await provider.listSandboxes();
      
      expect(sandboxes).toHaveLength(1);
      expect(sandboxes[0].id).toBe('abc123');
      expect(sandboxes[0].provider).toBe('local-docker');
      expect(sandboxes[0].status).toBe(SandboxStatus.RUNNING);
    });
  });

  describe('startSandbox', () => {
    it('should start container with retry on network error', async () => {
      vi.mocked(dockerService.startContainer)
        .mockRejectedValueOnce(new Error('ECONNREFUSED'))
        .mockRejectedValueOnce(new Error('ECONNREFUSED'))
        .mockResolvedValueOnce(undefined);

      const error1 = new Error('Connection refused');
      (error1 as any).code = 'ECONNREFUSED';
      const error2 = new Error('Connection refused');
      (error2 as any).code = 'ECONNREFUSED';
      
      vi.mocked(dockerService.startContainer)
        .mockRejectedValueOnce(error1)
        .mockRejectedValueOnce(error2)
        .mockResolvedValue(undefined);

      await provider.startSandbox('abc123');
      
      expect(dockerService.startContainer).toHaveBeenCalledTimes(3);
    });

    it('should fail immediately on auth error', async () => {
      const authError = new Error('authentication failed');
      vi.mocked(dockerService.startContainer).mockRejectedValue(authError);

      await expect(provider.startSandbox('abc123')).rejects.toThrow(authError);
      expect(dockerService.startContainer).toHaveBeenCalledTimes(1);
    });
  });

  describe('testConnection', () => {
    it('should return true when connection succeeds', async () => {
      vi.mocked(dockerService.listContainers).mockResolvedValue([]);

      const result = await provider.testConnection();
      expect(result).toBe(true);
    });

    it('should return false when connection fails', async () => {
      vi.mocked(dockerService.listContainers).mockRejectedValue(new Error('Connection failed'));

      const result = await provider.testConnection();
      expect(result).toBe(false);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- LocalDockerProvider.test.ts`

Expected: FAIL with "LocalDockerProvider is not defined"

- [ ] **Step 3: Implement LocalDockerProvider**

```typescript
// src/providers/local-docker/LocalDockerProvider.ts

import { BaseProvider } from '../base/BaseProvider';
import {
  Sandbox,
  SandboxStatusDetail,
  ExecResult,
  ProviderConfig,
  LocalDockerProviderConfig,
  SandboxStatus,
  ProviderType
} from '../types';
import {
  listContainers,
  startContainer,
  stopContainer,
  deleteContainer,
  createContainer
} from '../../services/docker';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Local Docker Provider
 * Wraps existing docker service to implement IProvider interface
 */
export class LocalDockerProvider extends BaseProvider {
  declare config: LocalDockerProviderConfig;

  constructor(id: string, config: LocalDockerProviderConfig) {
    super(id, config);
  }

  /**
   * List all sandboxes
   */
  async listSandboxes(): Promise<Sandbox[]> {
    return this.executeWithRetry(async () => {
      const containers = await listContainers();
      return containers.map(c => ({
        id: c.id,
        name: c.name,
        status: this.mapContainerStatus(c.status),
        provider: this.id,
        containerName: c.name,
        createdAt: new Date(c.createdAt)
      }));
    });
  }

  /**
   * Start a sandbox
   */
  async startSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await startContainer(id);
    });
  }

  /**
   * Stop a sandbox
   */
  async stopSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await stopContainer(id);
    });
  }

  /**
   * Restart a sandbox
   */
  async restartSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await stopContainer(id);
      await startContainer(id);
    });
  }

  /**
   * Get sandbox status
   */
  async getSandboxStatus(id: string): Promise<SandboxStatusDetail> {
    return this.executeWithRetry(async () => {
      const containers = await listContainers();
      const container = containers.find(c => c.id === id);
      
      if (!container) {
        throw new Error(`Sandbox ${id} not found`);
      }

      // Get stats for resource usage
      let cpu: number | undefined;
      let memory: number | undefined;
      
      try {
        const statsOutput = await execAsync(`docker stats ${id} --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}"`);
        const [cpuStr, memStr] = statsOutput.stdout.trim().split('\t');
        cpu = parseFloat(cpuStr.replace('%', ''));
        const [used, total] = memStr.split(/\s*\/\s*/);
        memory = parseFloat(used) / parseFloat(total) * 100;
      } catch {
        // Stats not available
      }

      return {
        status: this.mapContainerStatus(container.status),
        cpu,
        memory,
        ip: container.ip
      };
    });
  }

  /**
   * Execute command in sandbox
   */
  async execCommand(id: string, command: string): Promise<ExecResult> {
    return this.executeWithRetry(async () => {
      try {
        const { stdout, stderr } = await execAsync(`docker exec ${id} sh -c '${command.replace(/'/g, "'\\''")}'`);
        return { exitCode: 0, stdout, stderr };
      } catch (error: any) {
        return {
          exitCode: error.code || 1,
          stdout: error.stdout || '',
          stderr: error.stderr || error.message
        };
      }
    });
  }

  /**
   * Upload file to sandbox (via docker cp)
   */
  async uploadFile(id: string, localPath: string, remotePath: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await execAsync(`docker cp ${localPath} ${id}:${remotePath}`);
    });
  }

  /**
   * Download file from sandbox (via docker cp)
   */
  async downloadFile(id: string, remotePath: string, localPath: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await execAsync(`docker cp ${id}:${remotePath} ${localPath}`);
    });
  }

  /**
   * Get sandbox logs
   */
  async getLogs(id: string, tail: number = 100): Promise<string> {
    return this.executeWithRetry(async () => {
      const { stdout } = await execAsync(`docker logs --tail ${tail} ${id}`);
      return stdout;
    });
  }

  /**
   * Delete sandbox
   */
  async deleteSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      await deleteContainer(id);
    });
  }

  /**
   * Test if Docker is accessible
   */
  async testConnection(): Promise<boolean> {
    try {
      await execAsync('docker info');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Map container status to SandboxStatus enum
   */
  private mapContainerStatus(status: string): SandboxStatus {
    const s = status.toLowerCase();
    if (s === 'running') return SandboxStatus.RUNNING;
    if (s === 'exited' || s === 'stopped') return SandboxStatus.STOPPED;
    return SandboxStatus.ERROR;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- LocalDockerProvider.test.ts`

Expected: PASS (may need to adjust mocks based on actual docker service)

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/local-docker/LocalDockerProvider.ts src/providers/local-docker/LocalDockerProvider.test.ts
git commit -m "feat: add LocalDockerProvider

Implement LocalDockerProvider that wraps existing docker service
with retry logic and unified IProvider interface.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Create SSH Client Utility

**Files:**
- Create: `repos/ce-orchestrator/src/utils/ssh-client.ts`
- Create: `repos/ce-orchestrator/src/utils/ssh-client.test.ts`

- [ ] **Step 1: Write SSH client test**

```typescript
// src/utils/ssh-client.test.ts

import { describe, it, expect, vi } from 'vitest';
import { SSHClient } from './ssh-client';
import { SSHAuth } from '../providers/types';

// Mock ssh2-sftp-client
vi.mock('ssh2-sftp-client', () => ({
  default: class MockClient {
    connect() { return Promise.resolve(); }
    executeCommand() { return Promise.resolve({ stdout: 'success', stderr: '' }); }
    end() { return Promise.resolve(); }
  }
}));

describe('SSHClient', () => {
  const auth: SSHAuth = { type: 'privateKey', keyPath: '~/.ssh/test.pem' };
  
  describe('constructor', () => {
    it('should initialize with connection config', () => {
      const client = new SSHClient('test.com', 22, 'root', auth);
      expect(client.host).toBe('test.com');
      expect(client.port).toBe(22);
      expect(client.username).toBe('root');
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- ssh-client.test.ts`

Expected: FAIL with "SSHClient is not defined"

- [ ] **Step 3: Implement SSH client**

```typescript
// src/utils/ssh-client.ts

import Client from 'ssh2-sftp-client';
import { SSHAuth } from '../providers/types';
import { homedir } from 'os';
import { join } from 'path';
import { existsSync, readFileSync } from 'fs';

/**
 * SSH client wrapper for executing commands and file operations
 */
export class SSHClient {
  readonly host: string;
  readonly port: number;
  readonly username: string;
  readonly auth: SSHAuth;
  private client: Client | null = null;

  constructor(host: string, port: number, username: string, auth: SSHAuth) {
    this.host = host;
    this.port = port;
    this.username = username;
    this.auth = auth;
  }

  /**
   * Connect to SSH server
   */
  async connect(): Promise<void> {
    if (this.client) {
      return; // Already connected
    }

    this.client = new Client();

    const config: any = {
      host: this.host,
      port: this.port,
      username: this.username
    };

    // Configure authentication
    if (this.auth.type === 'privateKey') {
      const keyPath = this.auth.keyPath.startsWith('~')
        ? join(homedir(), this.auth.keyPath.slice(1))
        : this.auth.keyPath;

      if (!existsSync(keyPath)) {
        throw new Error(`SSH key not found: ${keyPath}`);
      }

      config.privateKey = readFileSync(keyPath);
      if (this.auth.passphrase) {
        config.passphrase = this.auth.passphrase;
      }
    } else if (this.auth.type === 'password') {
      config.password = this.auth.password;
    }

    await this.client.connect(config);
  }

  /**
   * Execute a command on the remote server
   */
  async executeCommand(command: string): Promise<{ stdout: string; stderr: string; exitCode: number }> {
    if (!this.client) {
      await this.connect();
    }

    // SSH2-sftp-client doesn't have direct execute, use exec
    return new Promise((resolve, reject) => {
      const { Client: SSHClient } = require('ssh2');
      const conn = new SSHClient();

      const config: any = {
        host: this.host,
        port: this.port,
        username: this.username
      };

      if (this.auth.type === 'privateKey') {
        const keyPath = this.auth.keyPath.startsWith('~')
          ? join(homedir(), this.auth.keyPath.slice(1))
          : this.auth.keyPath;
        config.privateKey = readFileSync(keyPath);
        if (this.auth.passphrase) {
          config.passphrase = this.auth.passphrase;
        }
      } else {
        config.password = this.auth.password;
      }

      conn.on('ready', () => {
        conn.exec(command, (err: any, stream: any) => {
          if (err) {
            conn.end();
            return reject(err);
          }

          let stdout = '';
          let stderr = '';

          stream.on('close', (code: number) => {
            conn.end();
            resolve({ stdout, stderr, exitCode: code || 0 });
          });

          stream.stdout.on('data', (data: Buffer) => {
            stdout += data.toString();
          });

          stream.stderr.on('data', (data: Buffer) => {
            stderr += data.toString();
          });

          stream.end();
        });
      });

      conn.on('error', (err: Error) => {
        reject(err);
      });

      conn.connect(config);
    });
  }

  /**
   * Upload a file via SFTP
   */
  async uploadFile(localPath: string, remotePath: string): Promise<void> {
    if (!this.client) {
      await this.connect();
    }
    await this.client.fastPut(localPath, remotePath);
  }

  /**
   * Download a file via SFTP
   */
  async downloadFile(remotePath: string, localPath: string): Promise<void> {
    if (!this.client) {
      await this.connect();
    }
    await this.client.fastGet(remotePath, localPath);
  }

  /**
   * Disconnect from SSH server
   */
  async disconnect(): Promise<void> {
    if (this.client) {
      await this.client.end();
      this.client = null;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- ssh-client.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/utils/ssh-client.ts src/utils/ssh-client.test.ts
git commit -m "feat: add SSH client utility

Implement SSH client wrapper for remote command execution
and file transfer operations.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 7: Create AliyunProvider

**Files:**
- Create: `repos/ce-orchestrator/src/providers/aliyun/AliyunProvider.ts`
- Create: `repos/ce-orchestrator/src/providers/aliyun/AliyunProvider.test.ts`

- [ ] **Step 1: Write AliyunProvider test**

```typescript
// src/providers/aliyun/AliyunProvider.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AliyunProvider } from './AliyunProvider';
import { ProviderType, SandboxStatus } from '../../types';
import { SSHClient } from '../../utils/ssh-client';

vi.mock('../../utils/ssh-client');

describe('AliyunProvider', () => {
  let provider: AliyunProvider;
  const mockConfig = {
    type: ProviderType.ALIYUN,
    host: 'ecs.test.com',
    port: 22,
    username: 'root',
    auth: { type: 'privateKey', keyPath: '~/.ssh/test.pem' },
    dockerNetwork: 'kai-net',
    baseRoot: '/workspace'
  };

  beforeEach(() => {
    provider = new AliyunProvider('aliyun-prod', mockConfig);
    vi.clearAllMocks();
  });

  describe('constructor', () => {
    it('should initialize with config', () => {
      expect(provider.id).toBe('aliyun-prod');
      expect(provider.config).toEqual(mockConfig);
    });
  });

  describe('execCommand', () => {
    it('should execute command via SSH', async () => {
      const mockClient = {
        executeCommand: vi.fn().mockResolvedValue({ stdout: 'output', stderr: '', exitCode: 0 })
      };
      vi.mocked(SSHClient).mockImplementation as any = () => mockClient;

      const result = await provider.execCommand('test-sandbox', 'ls -la');
      expect(result.exitCode).toBe(0);
      expect(result.stdout).toBe('output');
    });
  });

  describe('testConnection', () => {
    it('should return true when SSH connection succeeds', async () => {
      const mockClient = {
        executeCommand: vi.fn().mockResolvedValue({ stdout: 'ok', stderr: '', exitCode: 0 }),
        connect: vi.fn().mockResolvedValue(undefined),
        disconnect: vi.fn().mockResolvedValue(undefined)
      };
      vi.mocked(SSHClient).mockImplementation as any = () => mockClient;

      const result = await provider.testConnection();
      expect(result).toBe(true);
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- AliyunProvider.test.ts`

Expected: FAIL with "AliyunProvider is not defined"

- [ ] **Step 3: Implement AliyunProvider**

```typescript
// src/providers/aliyun/AliyunProvider.ts

import { BaseProvider } from '../base/BaseProvider';
import {
  Sandbox,
  SandboxStatusDetail,
  ExecResult,
  ProviderConfig,
  AliyunProviderConfig,
  SandboxStatus,
  ProviderType
} from '../types';
import { SSHClient } from '../../utils/ssh-client';

/**
 * Aliyun ECS Provider
 * Manages sandboxes on Aliyun ECS via SSH + Docker
 */
export class AliyunProvider extends BaseProvider {
  declare config: AliyunProviderConfig;
  private sshClient: SSHClient | null = null;

  constructor(id: string, config: AliyunProviderConfig) {
    super(id, config);
  }

  /**
   * Get SSH client (lazy initialization)
   */
  private getSSH(): SSHClient {
    if (!this.sshClient) {
      this.sshClient = new SSHClient(
        this.config.host,
        this.config.port,
        this.config.username,
        this.config.auth
      );
    }
    return this.sshClient;
  }

  /**
   * List all sandboxes
   */
  async listSandboxes(): Promise<Sandbox[]> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      const { stdout } = await ssh.executeCommand(
        `docker ps -a --filter "network=${this.config.dockerNetwork}" --format "{{.ID}}\t{{.Names}}\t{{.State}}\t{{.CreatedAt}}"`
      );

      const lines = stdout.trim().split('\n').filter(l => l);
      return lines.map(line => {
        const [id, name, status, createdAt] = line.split('\t');
        return {
          id,
          name: name.replace(/^\//, ''),
          status: this.mapDockerStatus(status),
          provider: this.id,
          containerName: name.replace(/^\//, ''),
          createdAt: new Date(createdAt)
        };
      });
    });
  }

  /**
   * Start a sandbox
   */
  async startSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      await ssh.executeCommand(`docker start ${id}`);
    });
  }

  /**
   * Stop a sandbox
   */
  async stopSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      await ssh.executeCommand(`docker stop ${id}`);
    });
  }

  /**
   * Restart a sandbox
   */
  async restartSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      await ssh.executeCommand(`docker restart ${id}`);
    });
  }

  /**
   * Get sandbox status
   */
  async getSandboxStatus(id: string): Promise<SandboxStatusDetail> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      
      // Get container state
      const { stdout: stateOutput } = await ssh.executeCommand(
        `docker inspect --format '{{.State.Status}}' ${id}`
      );
      const status = this.mapDockerStatus(stateOutput.trim());

      // Get IP address
      let ip: string | undefined;
      try {
        const { stdout: ipOutput } = await ssh.executeCommand(
          `docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${id}`
        );
        ip = ipOutput.trim() || undefined;
      } catch {
        // IP not available
      }

      // Get stats
      let cpu: number | undefined;
      let memory: number | undefined;
      try {
        const { stdout: statsOutput } = await ssh.executeCommand(
          `docker stats ${id} --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}"`
        );
        const [cpuStr, memStr] = statsOutput.trim().split('\t');
        cpu = parseFloat(cpuStr.replace('%', ''));
        const [used, total] = memStr.split(/\s*\/\s*/);
        memory = (parseFloat(used) / parseFloat(total)) * 100;
      } catch {
        // Stats not available
      }

      return { status, cpu, memory, ip };
    });
  }

  /**
   * Execute command in sandbox
   */
  async execCommand(id: string, command: string): Promise<ExecResult> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      const escapedCommand = command.replace(/'/g, "'\\''");
      return await ssh.executeCommand(`docker exec ${id} sh -c '${escapedCommand}'`);
    });
  }

  /**
   * Upload file to sandbox
   */
  async uploadFile(id: string, localPath: string, remotePath: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      // First upload to /tmp on remote host
      const tmpPath = `/tmp/upload_${Date.now()}`;
      await ssh.uploadFile(localPath, tmpPath);
      // Then copy into container
      await ssh.executeCommand(`docker cp ${tmpPath} ${id}:${remotePath}`);
      await ssh.executeCommand(`rm ${tmpPath}`);
    });
  }

  /**
   * Download file from sandbox
   */
  async downloadFile(id: string, remotePath: string, localPath: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      // First copy from container to /tmp on remote host
      const tmpPath = `/tmp/download_${Date.now()}`;
      await ssh.executeCommand(`docker cp ${id}:${remotePath} ${tmpPath}`);
      // Then download from remote host
      await ssh.downloadFile(tmpPath, localPath);
      await ssh.executeCommand(`rm ${tmpPath}`);
    });
  }

  /**
   * Get sandbox logs
   */
  async getLogs(id: string, tail: number = 100): Promise<string> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      const { stdout } = await ssh.executeCommand(`docker logs --tail ${tail} ${id}`);
      return stdout;
    });
  }

  /**
   * Delete sandbox
   */
  async deleteSandbox(id: string): Promise<void> {
    return this.executeWithRetry(async () => {
      const ssh = this.getSSH();
      await ssh.executeCommand(`docker rm -f ${id}`);
    });
  }

  /**
   * Test SSH connection to Aliyun ECS
   */
  async testConnection(): Promise<boolean> {
    try {
      const ssh = this.getSSH();
      await ssh.executeCommand('docker --version');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Cleanup SSH connection
   */
  async cleanup(): Promise<void> {
    if (this.sshClient) {
      await this.sshClient.disconnect();
      this.sshClient = null;
    }
  }

  /**
   * Map Docker status to SandboxStatus
   */
  private mapDockerStatus(status: string): SandboxStatus {
    const s = status.toLowerCase();
    if (s === 'running') return SandboxStatus.RUNNING;
    if (s === 'exited') return SandboxStatus.STOPPED;
    return SandboxStatus.ERROR;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- AliyunProvider.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/aliyun/AliyunProvider.ts src/providers/aliyun/AliyunProvider.test.ts
git commit -m "feat: add AliyunProvider

Implement Aliyun ECS provider using SSH for remote Docker
container management with retry logic.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 3: Provider Factory and Manager

### Task 8: Create Provider Factory

**Files:**
- Create: `repos/ce-orchestrator/src/providers/factory.ts`
- Create: `repos/ce-orchestrator/src/providers/factory.test.ts`

- [ ] **Step 1: Write factory test**

```typescript
// src/providers/factory.test.ts

import { describe, it, expect } from 'vitest';
import { createProvider } from './factory';
import { LocalDockerProvider } from './local-docker/LocalDockerProvider';
import { AliyunProvider } from './aliyun/AliyunProvider';
import { ProviderType } from './types';

describe('Provider Factory', () => {
  describe('createProvider', () => {
    it('should create LocalDockerProvider', () => {
      const config = {
        type: ProviderType.LOCAL_DOCKER,
        dockerNetwork: 'kai-net',
        baseRoot: '/KaiBase'
      };
      
      const provider = createProvider('local', config);
      expect(provider).toBeInstanceOf(LocalDockerProvider);
      expect(provider.id).toBe('local');
    });

    it('should create AliyunProvider', () => {
      const config = {
        type: ProviderType.ALIYUN,
        host: 'ecs.test.com',
        port: 22,
        username: 'root',
        auth: { type: 'privateKey', keyPath: '~/.ssh/test.pem' },
        dockerNetwork: 'kai-net',
        baseRoot: '/workspace'
      };
      
      const provider = createProvider('aliyun', config);
      expect(provider).toBeInstanceOf(AliyunProvider);
      expect(provider.id).toBe('aliyun');
    });

    it('should throw error for unknown provider type', () => {
      const config = { type: 'unknown' as any };
      
      expect(() => createProvider('test', config)).toThrow('Unknown provider type');
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- factory.test.ts`

Expected: FAIL with "createProvider is not defined"

- [ ] **Step 3: Implement factory**

```typescript
// src/providers/factory.ts

import { BaseProvider } from './base/BaseProvider';
import { LocalDockerProvider } from './local-docker/LocalDockerProvider';
import { AliyunProvider } from './aliyun/AliyunProvider';
import { ProviderConfig, ProviderType } from './types';

/**
 * Create a provider instance based on config type
 */
export function createProvider(id: string, config: ProviderConfig): BaseProvider {
  switch (config.type) {
    case ProviderType.LOCAL_DOCKER:
      return new LocalDockerProvider(id, config);
    
    case ProviderType.ALIYUN:
      return new AliyunProvider(id, config);
    
    default:
      throw new Error(`Unknown provider type: ${(config as any).type}`);
  }
}

/**
 * Get all supported provider types
 */
export function getSupportedProviderTypes(): ProviderType[] {
  return [
    ProviderType.LOCAL_DOCKER,
    ProviderType.ALIYUN
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- factory.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/factory.ts src/providers/factory.test.ts
git commit -m "feat: add provider factory

Implement factory pattern for creating provider instances
based on configuration type.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 9: Create Configuration Loader

**Files:**
- Create: `repos/ce-orchestrator/src/providers/config.ts`
- Create: `repos/ce-orchestrator/src/providers/config.test.ts`

- [ ] **Step 1: Write config loader test**

```typescript
// src/providers/config.test.ts

import { describe, it, expect, vi } from 'vitest';
import { loadProviderConfig, expandEnvVars } from './config';
import { readFileSync } from 'fs';
import * as yaml from 'js-yaml';

vi.mock('fs', () => ({
  existsSync: vi.fn(),
  readFileSync: vi.fn()
}));

describe('Configuration Loader', () => {
  describe('expandEnvVars', () => {
    it('should expand environment variables', () => {
      process.env.TEST_VAR = 'test-value';
      const input = '${TEST_VAR}';
      const result = expandEnvVars(input);
      expect(result).toBe('test-value');
      delete process.env.TEST_VAR;
    });

    it('should leave non-env strings unchanged', () => {
      const input = 'plain-string';
      const result = expandEnvVars(input);
      expect(result).toBe('plain-string');
    });

    it('should handle mixed content', () => {
      process.env.PREFIX = 'pre';
      const input = 'prefix-${PREFIX}-suffix';
      const result = expandEnvVars(input);
      expect(result).toBe('prefix-pre-suffix');
      delete process.env.PREFIX;
    });
  });

  describe('loadProviderConfig', () => {
    it('should load and parse configuration file', () => {
      const mockConfig = {
        providers: {
          'local-docker': {
            type: 'local-docker',
            dockerNetwork: 'kai-net',
            baseRoot: '~/KaiBase'
          }
        },
        sandboxes: {
          'local-dev': {
            provider: 'local-docker',
            container: 'flexy-local-dev'
          }
        }
      };
      
      vi.mocked(readFileSync).mockReturnValue(JSON.stringify(mockConfig));
      
      const config = loadProviderConfig('/test/config.yaml');
      expect(config.providers).toBeDefined();
      expect(config.sandboxes).toBeDefined();
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- config.test.ts`

Expected: FAIL with "loadProviderConfig is not defined"

- [ ] **Step 3: Implement config loader**

```typescript
// src/providers/config.ts

import { readFileSync, existsSync } from 'fs';
import * as yaml from 'js-yaml';
import { ProvidersConfiguration, ProviderConfig, SandboxConfig } from './types';
import { homedir } from 'os';

/**
 * Default configuration file path
 */
export const DEFAULT_CONFIG_PATH = 'config/providers.yaml';

/**
 * Expand environment variables in string
 * Supports ${VAR_NAME} syntax
 */
export function expandEnvVars(str: string): string {
  return str.replace(/\$\{([^}]+)\}/g, (_, varName) => {
    return process.env[varName] || '';
  });
}

/**
 * Expand ~ to home directory
 */
export function expandHomeDir(path: string): string {
  if (path.startsWith('~/')) {
    return path.replace('~', homedir());
  }
  return path;
}

/**
 * Process configuration values (expand env vars and home dir)
 */
function processConfig(config: any): any {
  if (typeof config === 'string') {
    return expandEnvVars(expandHomeDir(config));
  }
  
  if (Array.isArray(config)) {
    return config.map(processConfig);
  }
  
  if (config && typeof config === 'object') {
    const result: any = {};
    for (const [key, value] of Object.entries(config)) {
      result[key] = processConfig(value);
    }
    return result;
  }
  
  return config;
}

/**
 * Load provider configuration from YAML file
 */
export function loadProviderConfig(configPath: string = DEFAULT_CONFIG_PATH): ProvidersConfiguration {
  if (!existsSync(configPath)) {
    throw new Error(`Configuration file not found: ${configPath}`);
  }

  const content = readFileSync(configPath, 'utf8');
  const rawConfig = yaml.load(content) as any;
  
  // Process configuration (expand env vars, etc.)
  const processedConfig = processConfig(rawConfig);
  
  // Validate structure
  if (!processedConfig.providers || typeof processedConfig.providers !== 'object') {
    throw new Error('Invalid configuration: missing or invalid "providers" section');
  }
  
  if (!processedConfig.sandboxes || typeof processedConfig.sandboxes !== 'object') {
    throw new Error('Invalid configuration: missing or invalid "sandboxes" section');
  }
  
  return processedConfig as ProvidersConfiguration;
}

/**
 * Load provider configuration with fallback to default
 */
export function loadProviderConfigSafe(configPath?: string): ProvidersConfiguration | null {
  try {
    return loadProviderConfig(configPath);
  } catch {
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- config.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/config.ts src/providers/config.test.ts
git commit -m "feat: add provider configuration loader

Implement YAML configuration loader with environment variable
expansion and home directory support.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 10: Create ProviderManager

**Files:**
- Create: `repos/ce-orchestrator/src/providers/ProviderManager.ts`
- Create: `repos/ce-orchestrator/src/providers/ProviderManager.test.ts`

- [ ] **Step 1: Write ProviderManager test**

```typescript
// src/providers/ProviderManager.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ProviderManager } from './ProviderManager';
import { loadProviderConfig } from './config';
import { createProvider } from './factory';
import { ProviderType } from './types';

vi.mock('./config');
vi.mock('./factory');

describe('ProviderManager', () => {
  let manager: ProviderManager;

  beforeEach(() => {
    vi.clearAllMocks();
    
    vi.mocked(loadProviderConfig).mockReturnValue({
      providers: {
        'local-docker': {
          type: ProviderType.LOCAL_DOCKER,
          dockerNetwork: 'kai-net',
          baseRoot: '~/KaiBase'
        } as any
      },
      sandboxes: {
        'local-dev': {
          provider: 'local-docker',
          container: 'flexy-local-dev'
        }
      }
    });
  });

  describe('constructor', () => {
    it('should load configuration and create providers', () => {
      const mockProvider = {
        id: 'local-docker',
        listSandboxes: vi.fn(),
        startSandbox: vi.fn(),
        stopSandbox: vi.fn(),
        restartSandbox: vi.fn(),
        getSandboxStatus: vi.fn(),
        execCommand: vi.fn(),
        uploadFile: vi.fn(),
        downloadFile: vi.fn(),
        getLogs: vi.fn(),
        deleteSandbox: vi.fn(),
        testConnection: vi.fn()
      };
      
      vi.mocked(createProvider).mockReturnValue(mockProvider as any);
      
      manager = new ProviderManager();
      
      expect(loadProviderConfig).toHaveBeenCalled();
      expect(createProvider).toHaveBeenCalledWith(
        'local-docker',
        expect.any(Object)
      );
    });
  });

  describe('getProvider', () => {
    it('should return provider by id', () => {
      const mockProvider = {
        id: 'test',
        testConnection: vi.fn()
      };
      vi.mocked(createProvider).mockReturnValue(mockProvider as any);
      
      manager = new ProviderManager();
      
      const provider = manager.getProvider('local-docker');
      expect(provider).toBeDefined();
    });

    it('should throw for unknown provider', () => {
      vi.mocked(createProvider).mockReturnValue({
        id: 'test',
        testConnection: vi.fn()
      } as any);
      
      manager = new ProviderManager();
      
      expect(() => manager.getProvider('unknown')).toThrow('Provider not found');
    });
  });

  describe('getSandboxProvider', () => {
    it('should return provider for sandbox', () => {
      const mockProvider = {
        id: 'local-docker',
        testConnection: vi.fn()
      };
      vi.mocked(createProvider).mockReturnValue(mockProvider as any);
      
      manager = new ProviderManager();
      
      const provider = manager.getSandboxProvider('local-dev');
      expect(provider).toBe(mockProvider);
    });

    it('should throw for unknown sandbox', () => {
      vi.mocked(createProvider).mockReturnValue({
        id: 'test',
        testConnection: vi.fn()
      } as any);
      
      manager = new ProviderManager();
      
      expect(() => manager.getSandboxProvider('unknown')).toThrow('Sandbox not found');
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- ProviderManager.test.ts`

Expected: FAIL with "ProviderManager is not defined"

- [ ] **Step 3: Implement ProviderManager**

```typescript
// src/providers/ProviderManager.ts

import { BaseProvider } from './base/BaseProvider';
import { loadProviderConfig, DEFAULT_CONFIG_PATH } from './config';
import { createProvider } from './factory';
import { ProvidersConfiguration, SandboxConfig, ProviderInfo, ProviderType } from './types';

/**
 * Provider Manager
 * Manages multiple provider instances and routes operations to correct provider
 */
export class ProviderManager {
  private config: ProvidersConfiguration;
  private providers: Map<string, BaseProvider>;
  private sandboxes: Map<string, SandboxConfig>;

  constructor(configPath?: string) {
    // Load configuration
    this.config = loadProviderConfig(configPath || DEFAULT_CONFIG_PATH);
    this.providers = new Map();
    this.sandboxes = new Map();

    // Initialize providers
    this.initializeProviders();
  }

  /**
   * Initialize all providers from configuration
   */
  private initializeProviders(): void {
    for (const [id, providerConfig] of Object.entries(this.config.providers)) {
      const provider = createProvider(id, providerConfig);
      this.providers.set(id, provider);
    }

    // Initialize sandbox mapping
    for (const [id, sandboxConfig] of Object.entries(this.config.sandboxes)) {
      this.sandboxes.set(id, sandboxConfig);
    }
  }

  /**
   * Get provider by ID
   */
  getProvider(id: string): BaseProvider {
    const provider = this.providers.get(id);
    if (!provider) {
      throw new Error(`Provider not found: ${id}`);
    }
    return provider;
  }

  /**
   * Get provider for a specific sandbox
   */
  getSandboxProvider(sandboxId: string): BaseProvider {
    const sandboxConfig = this.sandboxes.get(sandboxId);
    if (!sandboxConfig) {
      throw new Error(`Sandbox not found: ${sandboxId}`);
    }
    return this.getProvider(sandboxConfig.provider);
  }

  /**
   * Get sandbox configuration
   */
  getSandboxConfig(sandboxId: string): SandboxConfig {
    const config = this.sandboxes.get(sandboxId);
    if (!config) {
      throw new Error(`Sandbox not found: ${sandboxId}`);
    }
    return config;
  }

  /**
   * List all providers
   */
  listProviders(): ProviderInfo[] {
    const infos: ProviderInfo[] = [];
    
    for (const [id, provider] of this.providers) {
      infos.push({
        id,
        type: (provider.config as any).type,
        status: 'connected' // TODO: implement actual status check
      });
    }
    
    return infos;
  }

  /**
   * List all sandboxes across all providers
   */
  async listAllSandboxes(): Promise<Map<string, Awaited<ReturnType<BaseProvider['listSandboxes']>[0]>> {
    const allSandboxes = new Map();
    
    for (const [sandboxId, sandboxConfig] of this.sandboxes) {
      try {
        const provider = this.getProvider(sandboxConfig.provider);
        const sandboxes = await provider.listSandboxes();
        
        // Find the matching sandbox
        const sandbox = sandboxes.find(s => 
          s.containerName === sandboxConfig.container || 
          s.id === sandboxConfig.container
        );
        
        if (sandbox) {
          allSandboxes.set(sandboxId, { ...sandbox, name: sandboxId });
        }
      } catch (error) {
        // Skip provider errors, continue with other sandboxes
        console.error(`Error listing sandboxes for ${sandboxId}:`, error);
      }
    }
    
    return allSandboxes;
  }

  /**
   * Test connection for a specific provider
   */
  async testProvider(providerId: string): Promise<{ status: 'connected' | 'failed'; message?: string }> {
    try {
      const provider = this.getProvider(providerId);
      const connected = await provider.testConnection();
      
      if (connected) {
        return { status: 'connected' };
      } else {
        return { status: 'failed', message: 'Connection test failed' };
      }
    } catch (error: any) {
      return { status: 'failed', message: error.message };
    }
  }

  /**
   * Test all provider connections
   */
  async testAllProviders(): Promise<Map<string, { status: 'connected' | 'failed'; message?: string }>> {
    const results = new Map();
    
    for (const providerId of this.providers.keys()) {
      const result = await this.testProvider(providerId);
      results.set(providerId, result);
    }
    
    return results;
  }

  /**
   * Get configuration
   */
  getConfiguration(): ProvidersConfiguration {
    return this.config;
  }
}

// Singleton instance
let defaultManager: ProviderManager | null = null;

/**
 * Get or create default ProviderManager instance
 */
export function getProviderManager(): ProviderManager {
  if (!defaultManager) {
    defaultManager = new ProviderManager();
  }
  return defaultManager;
}

/**
 * Reset default ProviderManager instance (for testing)
 */
export function resetProviderManager(): void {
  defaultManager = null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd repos/ce-orchestrator && pnpm test:unit -- ProviderManager.test.ts`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd repos/ce-orchestrator
git add src/providers/ProviderManager.ts src/providers/ProviderManager.test.ts
git commit -m "feat: add ProviderManager

Implement ProviderManager for managing multiple provider
instances and routing operations to correct provider.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 4: API Layer - RemoteSandboxController

### Task 11: Create RemoteSandboxController

**Files:**
- Create: `repos/ce-orchestrator/src/controllers/RemoteSandboxController.ts`

- [ ] **Step 1: Create RemoteSandboxController with TSOA decorators**

```typescript
// src/controllers/RemoteSandboxController.ts

import { Route, Get, Post, Delete, Query, Body, Path, Res, TsoaResponse, SuccessResponse } from 'tsoa';
import { Response } from 'express';
import { getProviderManager } from '../providers/ProviderManager';
import { Sandbox, SandboxStatusDetail, ExecResult, ProviderInfo } from '../providers/types';

interface ErrorResponse {
  message: string;
  details?: any;
}

interface SandboxesResponse {
  sandboxes: Sandbox[];
  providers: ProviderInfo[];
}

interface ExecCommandRequest {
  command: string;
  timeout?: number;
}

interface FileTransferRequest {
  localPath: string;
  remotePath: string;
}

@Route('/api/remote-sandboxes')
export class RemoteSandboxController {
  private manager = getProviderManager();

  /**
   * List all sandboxes across all providers
   */
  @Get('/')
  @SuccessResponse('200', 'Returns list of all sandboxes')
  async listSandboxes(@Res() response: TsoaResponse<200, SandboxesResponse>) {
    try {
      const sandboxesMap = await this.manager.listAllSandboxes();
      const providers = this.manager.listProviders();
      
      response.status(200).json({
        sandboxes: Array.from(sandboxesMap.values()),
        providers
      });
    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Start a sandbox
   */
  @Post('/:id/start')
  @SuccessResponse('200', 'Sandbox started successfully')
  async startSandbox(
    @Path() id: string,
    @Res() response: TsoaResponse<200, { message: string; sandbox: Sandbox }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    await provider.startSandbox(id);
    
    const sandboxes = await provider.listSandboxes();
    const sandbox = sandboxes.find(s => s.containerName === this.manager.getSandboxConfig(id).container);
    
    response.status(200).json({
      message: 'Sandbox started',
      sandbox: sandbox as Sandbox
    });
  }

  /**
   * Stop a sandbox
   */
  @Post('/:id/stop')
  @SuccessResponse('200', 'Sandbox stopped successfully')
  async stopSandbox(
    @Path() id: string,
    @Res() response: TsoaResponse<200, { message: string; sandbox: Sandbox }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    await provider.stopSandbox(id);
    
    const sandboxes = await provider.listSandboxes();
    const sandbox = sandboxes.find(s => s.containerName === this.manager.getSandboxConfig(id).container);
    
    response.status(200).json({
      message: 'Sandbox stopped',
      sandbox: sandbox as Sandbox
    });
  }

  /**
   * Restart a sandbox
   */
  @Post('/:id/restart')
  @SuccessResponse('200', 'Sandbox restarted successfully')
  async restartSandbox(
    @Path() id: string,
    @Res() response: TsoaResponse<200, { message: string; sandbox: Sandbox }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    await provider.restartSandbox(id);
    
    const sandboxes = await provider.listSandboxes();
    const sandbox = sandboxes.find(s => s.containerName === this.manager.getSandboxConfig(id).container);
    
    response.status(200).json({
      message: 'Sandbox restarted',
      sandbox: sandbox as Sandbox
    });
  }

  /**
   * Get sandbox status
   */
  @Get('/:id/status')
  @SuccessResponse('200', 'Returns sandbox status')
  async getSandboxStatus(
    @Path() id: string,
    @Res() response: TsoaResponse<200, SandboxStatusDetail>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    const status = await provider.getSandboxStatus(sandboxConfig.container);
    
    response.status(200).json(status);
  }

  /**
   * Get sandbox logs
   */
  @Get('/:id/logs')
  @SuccessResponse('200', 'Returns sandbox logs')
  async getLogs(
    @Path() id: string,
    @Query() tail?: number,
    @Res() response: TsoaResponse<200, { logs: string }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    const logs = await provider.getLogs(sandboxConfig.container, tail);
    
    response.status(200).json({ logs });
  }

  /**
   * Execute command in sandbox
   */
  @Post('/:id/exec')
  @SuccessResponse('200', 'Command executed successfully')
  async execCommand(
    @Path() id: string,
    @Body() body: ExecCommandRequest,
    @Res() response: TsoaResponse<200, ExecResult>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    const result = await provider.execCommand(sandboxConfig.container, body.command);
    
    response.status(200).json(result);
  }

  /**
   * Upload file to sandbox
   */
  @Post('/:id/upload')
  @SuccessResponse('200', 'File uploaded successfully')
  async uploadFile(
    @Path() id: string,
    @Body() body: FileTransferRequest,
    @Res() response: TsoaResponse<200, { message: string }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    await provider.uploadFile(sandboxConfig.container, body.localPath, body.remotePath);
    
    response.status(200).json({ message: 'File uploaded successfully' });
  }

  /**
   * Download file from sandbox
   */
  @Post('/:id/download')
  @SuccessResponse('200', 'File downloaded successfully')
  async downloadFile(
    @Path() id: string,
    @Body() body: FileTransferRequest,
    @Res() response: TsoaResponse<200, { message: string }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    await provider.downloadFile(sandboxConfig.container, body.remotePath, body.localPath);
    
    response.status(200).json({ message: 'File downloaded successfully' });
  }

  /**
   * Delete a sandbox
   */
  @Delete('/:id')
  @SuccessResponse('200', 'Sandbox deleted successfully')
  async deleteSandbox(
    @Path() id: string,
    @Res() response: TsoaResponse<200, { message: string }>
  ) {
    const provider = this.manager.getSandboxProvider(id);
    const sandboxConfig = this.manager.getSandboxConfig(id);
    await provider.deleteSandbox(sandboxConfig.container);
    
    response.status(200).json({ message: 'Sandbox deleted successfully' });
  }
}

@Route('/api/providers')
export class ProviderController {
  private manager = getProviderManager();

  /**
   * List all providers
   */
  @Get('/')
  @SuccessResponse('200', 'Returns list of all providers')
  async listProviders(@Res() response: TsoaResponse<200, { providers: ProviderInfo[] }>) {
    const providers = this.manager.listProviders();
    response.status(200).json({ providers });
  }

  /**
   * Test provider connection
   */
  @Post('/:id/test')
  @SuccessResponse('200', 'Connection test result')
  async testProvider(
    @Path() id: string,
    @Res() response: TsoaResponse<200, { status: 'connected' | 'failed'; message?: string }>
  ) {
    const result = await this.manager.testProvider(id);
    response.status(200).json(result);
  }
}
```

- [ ] **Step 2: Register routes in app.ts**

```typescript
// Add to app.ts - after existing route registration

import { RegisterRoutes } from './generated/routes';
import { RemoteSandboxController, ProviderController } from './controllers/RemoteSandboxController';

// RegisterRoutes will automatically pick up the new controllers
```

- [ ] **Step 3: Build TSOA routes**

Run: `cd repos/ce-orchestrator && pnpm build:api`

Expected: Routes generated successfully

- [ ] **Step 4: Create controller test**

```typescript
// tests/api/RemoteSandboxController.test.ts

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { resetProviderManager } from '../../src/providers/ProviderManager';

describe('RemoteSandboxController API', () => {
  beforeEach(() => {
    resetProviderManager();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('GET /api/remote-sandboxes', () => {
    it('should return list of sandboxes', async () => {
      const response = await request(app)
        .get('/api/remote-sandboxes')
        .expect(200);

      expect(response.body).toHaveProperty('sandboxes');
      expect(response.body).toHaveProperty('providers');
    });
  });

  describe('POST /api/providers/:id/test', () => {
    it('should test provider connection', async () => {
      const response = await request(app)
        .post('/api/providers/local-docker/test')
        .expect(200);

      expect(response.body).toHaveProperty('status');
    });
  });
});
```

- [ ] **Step 5: Run tests**

Run: `cd repos/ce-orchestrator && pnpm test:api -- RemoteSandboxController`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
cd repos/ce-orchestrator
git add src/controllers/RemoteSandboxController.ts tests/api/RemoteSandboxController.test.ts
git commit -m "feat: add RemoteSandboxController and ProviderController

Implement TSOA controllers for remote sandbox and provider
management APIs.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 5: Configuration and Documentation

### Task 12: Create Configuration Files

**Files:**
- Create: `repos/ce-orchestrator/config/providers.schema.yaml`
- Create: `repos/ce-orchestrator/config/providers.yaml.example`

- [ ] **Step 1: Create configuration schema**

```yaml
# config/providers.schema.yaml
# JSON Schema for providers.yaml configuration

$schema: http://json-schema.org/draft-07/schema#
title: Provider Configuration
type: object
required:
  - providers
  - sandboxes
properties:
  providers:
    type: object
    additionalProperties:
      oneOf:
        - $ref: '#/definitions/local-docker'
        - $ref: '#/definitions/aliyun'
  sandboxes:
    type: object
    additionalProperties:
      $ref: '#/definitions/sandbox'

definitions:
  local-docker:
    type: object
    required:
      - type
      - dockerNetwork
      - baseRoot
    properties:
      type:
        type: string
        enum: [local-docker]
      dockerNetwork:
        type: string
        description: Docker network name
      baseRoot:
        type: string
        description: Base root directory (supports ~ expansion)

  aliyun:
    type: object
    required:
      - type
      - host
      - port
      - username
      - auth
      - dockerNetwork
      - baseRoot
    properties:
      type:
        type: string
        enum: [aliyun]
      host:
        type: string
        description: ECS hostname or IP
      port:
        type: integer
        description: SSH port
        default: 22
      username:
        type: string
        description: SSH username
      auth:
        oneOf:
          - type: object
            required: [type, keyPath]
            properties:
              type:
                type: string
                enum: [privateKey]
              keyPath:
                type: string
                description: Path to private key file
              passphrase:
                type: string
                description: Optional passphrase for key
          - type: object
            required: [type, password]
            properties:
              type:
                type: string
                enum: [password]
              password:
                type: string
                description: SSH password
      dockerNetwork:
        type: string
      baseRoot:
        type: string

  sandbox:
    type: object
    required:
      - provider
      - container
    properties:
      provider:
        type: string
        description: Provider ID to use
      container:
        type: string
        description: Container name or ID
      description:
        type: string
        description: Human-readable description
      repos:
        type: array
        items:
          type: string
        description: List of repositories in this sandbox
```

- [ ] **Step 2: Create example configuration**

```yaml
# config/providers.yaml.example
# Example provider configuration file
# Copy this file to providers.yaml and customize for your environment

providers:
  # Local Docker Provider
  local-docker:
    type: local-docker
    dockerNetwork: kai-net
    baseRoot: ~/KaiBase

  # Aliyun ECS Provider
  # aliyun-prod:
  #   type: aliyun
  #   host: your-ecs-instance.com
  #   port: 22
  #   username: root
  #   auth:
  #     type: privateKey
  #     keyPath: ~/.ssh/aliyun.pem
  #   dockerNetwork: kai-net
  #   baseRoot: /workspace

sandboxes:
  # Local development sandbox
  local-dev:
    provider: local-docker
    container: flexy-local-dev
    description: Local development environment

  # Commercial products sandbox (Aliyun)
  # commercial-products:
  #   provider: aliyun-prod
  #   container: flexy-commercial-products
  #   description: Commercial product line
  #   repos:
  #     - flexyclaw
  #     - richmenu-editor
```

- [ ] **Step 3: Update .gitignore**

```bash
# Add to .gitignore
config/providers.yaml
```

- [ ] **Step 4: Commit**

```bash
cd repos/ce-orchestrator
git add config/providers.schema.yaml config/providers.yaml.example .gitignore
git commit -m "feat: add provider configuration files

Add configuration schema and example file for provider
and sandbox configuration.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 13: Create Usage Documentation

**Files:**
- Create: `repos/ce-orchestrator/docs/provider-abstraction.md`
- Update: `repos/ce-orchestrator/README.dev.md`

- [ ] **Step 1: Create provider abstraction documentation**

```markdown
# Provider Abstraction Layer

## Overview

The Provider Abstraction Layer enables ce-orchestrator to manage sandboxes across multiple providers (Local Docker, Aliyun ECS, AWS, etc.) through a unified API.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ce-orchestrator                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │       RemoteSandboxController (API)                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         ProviderManager                                 │   │
│  │  • Loads configuration                                 │   │
│  │  • Creates provider instances                          │   │
│  │  • Routes operations                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  ┌──────────────────┬──────────────────┬──────────────────┐   │
│  │  LocalDocker     │  AliyunProvider  │  AWSProvider     │   │
│  └──────────────────┴──────────────────┴──────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration

Create `config/providers.yaml`:

```yaml
providers:
  local-docker:
    type: local-docker
    dockerNetwork: kai-net
    baseRoot: ~/KaiBase

sandboxes:
  local-dev:
    provider: local-docker
    container: flexy-local-dev
```

## API Usage

### List Sandboxes

```bash
curl http://localhost:9900/api/remote-sandboxes
```

### Start Sandbox

```bash
curl -X POST http://localhost:9900/api/remote-sandboxes/local-dev/start
```

### Execute Command

```bash
curl -X POST http://localhost:9900/api/remote-sandboxes/local-dev/exec \
  -H "Content-Type: application/json" \
  -d '{"command": "ls -la"}'
```

## Adding a New Provider

1. Implement the `BaseProvider` interface:

```typescript
export class MyProvider extends BaseProvider {
  async listSandboxes(): Promise<Sandbox[]> { /* ... */ }
  async startSandbox(id: string): Promise<void> { /* ... */ }
  // ... implement other methods
}
```

2. Add to factory:

```typescript
// src/providers/factory.ts
case ProviderType.MY_PROVIDER:
  return new MyProvider(id, config);
```

3. Add configuration to `providers.yaml`

## Testing

```bash
# Unit tests
pnpm test:unit -- providers/

# Integration tests
pnpm test:e2e -- providers/
```
```

- [ ] **Step 2: Update README.dev.md**

Add section:

````markdown
## Provider Abstraction

The ce-orchestrator now supports multiple providers through a unified API:

- **Local Docker**: Direct Docker API access
- **Aliyun ECS**: Remote Docker via SSH

See [docs/provider-abstraction.md](docs/provider-abstraction.md) for details.
````

- [ ] **Step 3: Commit**

```bash
cd repos/ce-orchestrator
git add docs/provider-abstraction.md README.dev.md
git commit -m "docs: add provider abstraction documentation

Add usage guide and architecture overview for the provider
abstraction layer.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 14: Final Integration and Testing

- [ ] **Step 1: Build and verify**

Run: `cd repos/ce-orchestrator && pnpm build`

Expected: Build succeeds without errors

- [ ] **Step 2: Run all tests**

Run: `cd repos/ce-orchestrator && pnpm test`

Expected: All tests pass

- [ ] **Step 3: Generate API documentation**

Run: `cd repos/ce-orchestrator && pnpm build:docs`

Expected: Documentation generated

- [ ] **Step 4: Start development server**

Run: `cd repos/ce-orchestrator && pnpm dev`

Expected: Server starts on port 9900

- [ ] **Step 5: Test API endpoints**

```bash
# Test health
curl http://localhost:9900/health

# Test provider list
curl http://localhost:9900/api/providers

# Test sandbox list
curl http://localhost:9900/api/remote-sandboxes
```

Expected: All endpoints respond correctly

- [ ] **Step 6: Final commit**

```bash
cd repos/ce-orchestrator
git add -A
git commit -m "feat: complete provider abstraction layer implementation

This commit completes the multi-cloud provider abstraction layer:

- Smart retry logic with exponential backoff
- BaseProvider abstract class
- LocalDockerProvider (wraps existing docker service)
- AliyunProvider (SSH + remote Docker)
- Provider factory and manager
- RemoteSandboxController with TSOA routes
- Configuration loading with env var expansion
- Comprehensive unit and integration tests

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary

This implementation plan creates a complete provider abstraction layer with:

1. **Foundation**: Types, retry logic, base provider class
2. **Providers**: LocalDocker (reuse), Aliyun (new SSH-based)
3. **Management**: Factory, configuration loader, ProviderManager
4. **API**: TSOA controllers for remote operations
5. **Configuration**: YAML-based with env var support
6. **Testing**: Comprehensive unit and integration tests

Total estimated time: 6-8 days across 14 tasks.
