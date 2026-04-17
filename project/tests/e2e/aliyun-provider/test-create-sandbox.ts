/**
 * AliyunProvider createSandbox() E2E Test
 *
 * Tests createSandbox functionality for AliyunProvider.
 *
 * Usage:
 *   cd repos/ce-orchestrator && npx ts-node project/tests/e2e/aliyun-provider/test-create-sandbox.ts
 *
 * Prerequisites:
 *   - Build the project: pnpm build
 *   - ECS instance initialized
 */

import { AliyunProvider } from '../../../../repos/ce-orchestrator/src/providers/aliyun/AliyunProvider';
import { ProviderType, SandboxCreateOptions, SandboxStatus } from '../../../../repos/ce-orchestrator/src/providers/types';

// Colors
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[0;36m',
};

function log(message: string, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function success(message: string) {
  log(`✓ ${message}`, colors.green);
}

function error(message: string) {
  log(`✗ ${message}`, colors.red);
}

function info(message: string) {
  log(`ℹ ${message}`, colors.blue);
}

function section(message: string) {
  console.log('');
  log(`═══ ${message} ═══`, colors.cyan);
}

// Aliyun Provider Configuration
const ALIYUN_CONFIG = {
  type: ProviderType.ALIYUN,
  host: '8.134.76.139',
  port: 22,
  username: 'root',
  auth: {
    type: 'privateKey',
    keyPath: `${process.env.HOME}/.ssh/Aliyun-GZ.pem`,
  },
  dockerNetwork: 'kai-net',
  baseRoot: '/data',
};

// Test results
let passedTests = 0;
let failedTests = 0;
const createdContainers: string[] = [];

// Cleanup function
async function cleanup() {
  section('Cleanup');

  const aliyun = new AliyunProvider('test-aliyun', ALIYUN_CONFIG);

  for (const containerId of createdContainers) {
    try {
      await aliyun.deleteSandbox(containerId);
      log(`Cleaned up container: ${containerId.substring(0, 12)}`, colors.blue);
    } catch (err) {
      error(`Failed to cleanup container: ${err}`);
    }
  }

  await aliyun.cleanup();
}

// Test AliyunProvider.createSandbox()
async function testAliyunCreateSandbox() {
  section('AliyunProvider.createSandbox()');

  const provider = new AliyunProvider('test-aliyun-create', ALIYUN_CONFIG);
  const timestamp = Date.now().toString(36);

  // Test 1: Basic container creation
  info('Test 1: Basic container creation...');
  const basicOptions: SandboxCreateOptions = {
    name: `test-basic-${timestamp}`,
  };

  try {
    const containerId = await provider.createSandbox(basicOptions);
    success(`Container created: ${containerId.substring(0, 12)}`);
    createdContainers.push(containerId);
    passedTests++;

    // Verify container is running
    const status = await provider.getSandboxStatus(containerId);
    if (status.status === SandboxStatus.RUNNING) {
      success('Container status: RUNNING');
      passedTests++;
    } else {
      error(`Container status: ${status.status}`);
      failedTests++;
    }
  } catch (err) {
    error(`Failed to create container: ${err}`);
    failedTests++;
  }

  // Test 2: Container with environment variables
  info('Test 2: Container with environment variables...');
  const envOptions: SandboxCreateOptions = {
    name: `test-env-${timestamp}`,
    envVars: {
      TEST_VAR: 'test_value',
      NODE_ENV: 'production',
    },
  };

  try {
    const containerId = await provider.createSandbox(envOptions);
    success(`Container created: ${containerId.substring(0, 12)}`);
    createdContainers.push(containerId);
    passedTests++;

    // Verify environment variables
    const execResult = await provider.execCommand(containerId, 'echo $TEST_VAR');
    if (execResult.stdout.includes('test_value')) {
      success('Environment variables verified');
      passedTests++;
    } else {
      error('Environment variables not set correctly');
      failedTests++;
    }
  } catch (err) {
    error(`Failed to create container with env vars: ${err}`);
    failedTests++;
  }

  await provider.cleanup();
}

// Main test runner
async function main() {
  section('AliyunProvider createSandbox() E2E Test');
  log('Testing AliyunProvider createSandbox functionality', colors.yellow);
  console.log('');

  try {
    await testAliyunCreateSandbox();
  } catch (err) {
    error(`Test runner error: ${err}`);
  }

  await cleanup();

  // Summary
  section('Test Summary');
  const total = passedTests + failedTests;
  log(`Total tests: ${total}`, colors.cyan);
  log(`Passed: ${passedTests}`, colors.green);
  log(`Failed: ${failedTests}`, colors.red);

  if (failedTests === 0) {
    log('\n🎉 All createSandbox tests passed!', colors.green);
    process.exit(0);
  } else {
    log('\n⚠️ Some tests failed.', colors.yellow);
    process.exit(1);
  }
}

// Run tests
main().catch((err) => {
  error(`Fatal error: ${err}`);
  process.exit(1);
});
