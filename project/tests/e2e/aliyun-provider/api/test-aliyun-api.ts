/**
 * Comprehensive AliyunProvider API Test
 *
 * Tests AliyunProvider and ProviderManager with real ECS instance.
 * Uses actual API methods, not shell commands.
 *
 * Usage:
 *   cd repos/ce-orchestrator && npx ts-node test-aliyun-api.ts
 *
 * Prerequisites:
 *   - Build the project: pnpm build
 *   - Configure providers.yaml
 *   - ECS instance initialized
 */

import { ProviderManager } from './src/providers/ProviderManager';
import { loadProviderConfig } from './src/providers/configLoader';
import { AliyunProvider } from './src/providers/aliyun/AliyunProvider';
import { ProviderType, SandboxStatus } from './src/providers/types';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// Colors
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
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

// Direct provider configuration (for testing without config file)
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

async function runTests() {
  section('AliyunProvider API Test');
  log('Using direct provider instantiation (no config file needed)', colors.yellow);
  log('Target: 8.134.76.139 (aliyun-gz)', colors.yellow);
  console.log('');

  let passedTests = 0;
  let failedTests = 0;

  try {
    // Create provider instance directly
    const provider = new AliyunProvider('aliyun-test', ALIYUN_CONFIG);

    // Test 1: Connection
    section('Test 1: testConnection()');
    info('Calling provider.testConnection()...');
    const isConnected = await provider.testConnection();
    if (isConnected) {
      success('Connection successful');
      passedTests++;
    } else {
      error('Connection failed');
      failedTests++;
      return;
    }

    // Test 2: List Sandboxes
    section('Test 2: listSandboxes()');
    info('Calling provider.listSandboxes()...');
    const sandboxes = await provider.listSandboxes();
    success(`Found ${sandboxes.length} sandbox(es)`);
    if (sandboxes.length > 0) {
      info('Existing containers:');
      sandboxes.forEach((s, i) => {
        log(`  ${i + 1}. ${s.name} (${s.id.substring(0, 12)}) - ${s.status}`);
      });
    }
    passedTests++;

    // Test 3: Create test container via direct SSH
    section('Test 3: Setup - Create Test Container');
    const { SSHClient } = await import('./src/utils/ssh-client');
    const ssh = new SSHClient({
      host: ALIYUN_CONFIG.host,
      port: ALIYUN_CONFIG.port,
      username: ALIYUN_CONFIG.username,
      privateKeyPath: ALIYUN_CONFIG.auth.keyPath,
    });

    await ssh.connect();
    const timestamp = Date.now().toString(36);
    const containerName = `test-sandbox-${timestamp}`;

    info(`Creating container: ${containerName}`);
    const result = await ssh.executeCommand(
      `docker run -d --name ${containerName} --network ${ALIYUN_CONFIG.dockerNetwork} alpine:latest sleep 3600`
    );
    await ssh.disconnect();

    if (result.exitCode === 0) {
      const containerId = result.stdout.trim();
      success(`Container created: ${containerId.substring(0, 12)}`);

      // Test 4: Get Sandbox Status
      section('Test 4: getSandboxStatus()');
      info(`Calling provider.getSandboxStatus('${containerId}')...`);
      const status = await provider.getSandboxStatus(containerId);
      success(`Status: ${status.status}`);
      if (status.ip) info(`IP: ${status.ip}`);
      if (status.uptime) info(`Uptime: ${Math.round(status.uptime / 1000)}s`);
      passedTests++;

      // Test 5: Execute Command
      section('Test 5: execCommand()');
      info(`Calling provider.execCommand('${containerId}', 'echo Hello from API')...`);
      const execResult = await provider.execCommand(containerId, 'echo "Hello from API"');
      if (execResult.exitCode === 0) {
        success(`Command executed (exitCode: ${execResult.exitCode})`);
        if (execResult.stdout) {
          info(`Output: ${execResult.stdout}`);
        }
        passedTests++;
      } else {
        error(`Command failed: ${execResult.stderr || 'exit code ' + execResult.exitCode}`);
        failedTests++;
      }

      // Test 6: Get Logs
      section('Test 6: getLogs()');
      info(`Calling provider.getLogs('${containerId}', 10)...`);
      const logs = await provider.getLogs(containerId, 10);
      success(`Retrieved ${logs.split('\n').filter(l => l).length} log line(s)`);
      passedTests++;

      // Test 7: Stop Container
      section('Test 7: stopSandbox()');
      info(`Calling provider.stopSandbox('${containerId}')...`);
      await provider.stopSandbox(containerId);
      success('Container stopped');

      const stoppedStatus = await provider.getSandboxStatus(containerId);
      if (stoppedStatus.status === SandboxStatus.STOPPED) {
        success('Status confirmed: STOPPED');
        passedTests++;
      } else {
        error(`Status not updated: ${stoppedStatus.status}`);
        failedTests++;
      }

      // Test 8: Restart Container
      section('Test 8: restartSandbox()');
      info(`Calling provider.restartSandbox('${containerId}')...`);
      await provider.restartSandbox(containerId);
      success('Container restarted');

      const restartedStatus = await provider.getSandboxStatus(containerId);
      if (restartedStatus.status === SandboxStatus.RUNNING) {
        success('Status confirmed: RUNNING');
        passedTests++;
      } else {
        error(`Status not updated: ${restartedStatus.status}`);
        failedTests++;
      }

      // Test 9: File Upload
      section('Test 9: uploadFile()');
      const testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'aliyun-test-'));
      const testFile = path.join(testDir, 'test-upload.txt');
      fs.writeFileSync(testFile, 'Hello from uploadFile() API!\nTimestamp: ' + Date.now());

      info(`Calling provider.uploadFile('${containerId}', '${testFile}', '/tmp/test-file.txt')...`);
      await provider.uploadFile(containerId, testFile, '/tmp/test-file.txt');
      success('File uploaded');

      // Verify upload
      const verifyResult = await provider.execCommand(containerId, 'cat /tmp/test-file.txt');
      if (verifyResult.stdout.includes('Hello from uploadFile()')) {
        success('Upload verified: content matches');
        passedTests++;
      } else {
        error('Upload verification failed');
        failedTests++;
      }

      // Test 10: File Download
      section('Test 10: downloadFile()');
      const downloadPath = path.join(testDir, 'test-download.txt');

      // First create a file in container
      await ssh.connect();
      await ssh.executeCommand(`docker exec ${containerId} sh -c 'echo "Downloaded via API" > /tmp/test-download.txt'`);
      await ssh.disconnect();

      info(`Calling provider.downloadFile('${containerId}', '/tmp/test-download.txt', '${downloadPath}')...`);
      await provider.downloadFile(containerId, '/tmp/test-download.txt', downloadPath);
      success('File downloaded');

      // Verify download
      if (fs.existsSync(downloadPath)) {
        const downloadedContent = fs.readFileSync(downloadPath, 'utf-8');
        if (downloadedContent.includes('Downloaded via API')) {
          success('Download verified: content matches');
          passedTests++;
        } else {
          error('Download verification failed: content mismatch');
          failedTests++;
        }
      } else {
        error('Download failed: file not created');
        failedTests++;
      }

      // Cleanup
      fs.rmSync(testDir, { recursive: true });

      // Test 11: Delete Container
      section('Test 11: deleteSandbox()');
      info(`Calling provider.deleteSandbox('${containerId}')...`);
      await provider.deleteSandbox(containerId);
      success('Container deleted');

      const finalList = await provider.listSandboxes();
      const stillExists = finalList.some((s) => s.id === containerId);
      if (!stillExists) {
        success('Deletion verified: container no longer in list');
        passedTests++;
      } else {
        error('Container still exists after deletion');
        failedTests++;
      }

      // Cleanup provider
      await provider.cleanup();
    } else {
      error(`Failed to create container: ${result.stderr}`);
      failedTests++;
      await provider.cleanup();
    }

  } catch (err) {
    error(`Unexpected error: ${err instanceof Error ? err.message : String(err)}`);
    failedTests++;
  }

  // Summary
  section('Test Summary');
  const total = passedTests + failedTests;
  log(`Total tests: ${total}`, colors.cyan);
  log(`Passed: ${passedTests}`, colors.green);
  log(`Failed: ${failedTests}`, colors.red);

  if (failedTests === 0) {
    log('\n🎉 All API tests passed!', colors.green);
    log('\nAliyunProvider API is working correctly!', colors.green);
    process.exit(0);
  } else {
    log('\n⚠️ Some tests failed.', colors.yellow);
    process.exit(1);
  }
}

runTests().catch((err) => {
  error(`Test runner failed: ${err}`);
  process.exit(1);
});
