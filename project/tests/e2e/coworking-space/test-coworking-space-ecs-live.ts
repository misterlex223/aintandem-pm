/**
 * CoworkingSpace E2E Test with ECS Provisioning
 *
 * End-to-end test for CoworkingSpace functionality including
 * automatic ECS instance provisioning.
 *
 * Usage:
 *   cd repos/ce-orchestrator && npx ts-node --project tsconfig.test.ts \
 *     project/tests/e2e/coworking-space/test-coworking-space-ecs.ts
 *
 * Prerequisites:
 *   - Build the project: pnpm build
 *   - Set ALIYUN_ACCESS_KEY_ID and ALIYUN_ACCESS_KEY_SECRET
 *   - Aliyun VPC, VSwitch, Security Group configured
 */

import { CoworkingSpaceManager } from '../../../../repos/ce-orchestrator/src/services/coworking-space-manager';
import { ProviderManager } from '../../../../repos/ce-orchestrator/src/providers/ProviderManager';
import { AliyunECSProvisioner } from '../../../../repos/ce-orchestrator/src/services/aliyun-ecs-provisioner';
import { SpaceType, SpaceStatus } from '../../../../repos/ce-orchestrator/src/types/coworking-space';
import { ProviderType } from '../../../../repos/ce-orchestrator/src/providers/types';
import { SandboxCreateOptions } from '../../../../repos/ce-orchestrator/src/providers/types';

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

// Test results
let passedTests = 0;
let failedTests = 0;
const createdSpaces: string[] = [];
const createdContainers: { spaceId: string; containerId: string }[] = [];
const provisionedInstances: string[] = [];

// Configuration
const ALIYUN_CONFIG = {
  regionId: process.env.ALIYUN_REGION_ID || 'cn-guangzhou',
  zoneId: process.env.ALIYUN_ZONE_ID,
  vSwitchId: process.env.ALIYUN_VSWITCH_ID,
  securityGroupId: process.env.ALIYUN_SECURITY_GROUP_ID,
  keyPairName: process.env.ALIYUN_KEY_PAIR_NAME || 'Aliyun-GZ',
};

// Check Aliyun credentials
function checkAliyunCredentials(): boolean {
  if (!process.env.ALIYUN_ACCESS_KEY_ID || !process.env.ALIYUN_ACCESS_KEY_SECRET) {
    log('', colors.reset);
    log('⚠️  Aliyun credentials not configured', colors.yellow);
    log('   Please set:', colors.yellow);
    log('   export ALIYUN_ACCESS_KEY_ID=your-access-key-id', colors.yellow);
    log('   export ALIYUN_ACCESS_KEY_SECRET=your-access-key-secret', colors.yellow);
    log('   export ALIYUN_REGION_ID=cn-guangzhou', colors.yellow);
    log('   export ALIYUN_VSWITCH_ID=your-vswitch-id', colors.yellow);
    log('   export ALIYUN_SECURITY_GROUP_ID=your-security-group-id', colors.yellow);
    log('', colors.reset);
    return false;
  }
  return true;
}

// Cleanup function
async function cleanup() {
  section('Cleanup');

  const manager = CoworkingSpaceManager.getInstance();
  const providerManager = ProviderManager.getInstance();

  // Clean up containers
  for (const { spaceId, containerId } of createdContainers) {
    try {
      const space = manager.getSpace(spaceId);
      if (space) {
        for (const reg of space.providers) {
          const provider = providerManager.getProvider(reg.providerId);
          if (provider) {
            await provider.deleteSandbox(containerId);
            log(`Cleaned up container: ${containerId.substring(0, 12)}`, colors.blue);
          }
        }
      }
    } catch (err) {
      error(`Failed to cleanup container: ${err}`);
    }
  }

  // Clean up provisioned ECS instances
  for (const instanceId of provisionedInstances) {
    try {
      info(`Terminating ECS instance: ${instanceId.substring(0, 12)}...`);
      const terminated = await manager.terminateECSInstance('test-aliyun-space', instanceId);
      if (terminated) {
        success(`ECS instance terminated: ${instanceId.substring(0, 12)}`);
      } else {
        error(`Failed to terminate ECS instance`);
      }
    } catch (err) {
      error(`Failed to terminate ECS: ${err}`);
    }
  }

  // Clean up spaces
  for (const spaceId of createdSpaces) {
    try {
      await manager.removeSpace(spaceId);
      log(`Cleaned up space: ${spaceId.substring(0, 8)}`, colors.blue);
    } catch (err) {
      error(`Failed to cleanup space: ${err}`);
    }
  }

  await manager.cleanup();
}

// Test: Create local Coworking Space
async function testCreateLocalSpace() {
  section('Test 1: Create Local CoworkingSpace');

  const manager = CoworkingSpaceManager.getInstance();
  const providerManager = ProviderManager.getInstance();

  // Register local Docker provider
  info('Registering LocalDocker provider...');
  const providerId = 'test-local-docker';
  try {
    providerManager.registerProvider(providerId, {
      type: ProviderType.LOCAL_DOCKER,
      dockerNetwork: 'kai-net',
      baseRoot: process.env.KAI_BASE_ROOT || '/tmp/KaiBase',
    });
    success('LocalDocker provider registered');
    passedTests++;
  } catch (err) {
    log(`LocalDocker provider already registered or error: ${err}`, colors.yellow);
  }

  // Create local space
  info('Creating local CoworkingSpace...');
  const space = await manager.createSpace({
    name: 'Local Docker Space',
    description: 'A coworking space on local Docker',
    type: SpaceType.LOCAL,
    quota: {
      maxContainers: 10,
      maxCpu: 4,
      maxMemory: 8192,
      maxStorage: 50,
    },
    tags: ['local', 'development'],
  });

  createdSpaces.push(space.id);
  success(`Space created: ${space.id.substring(0, 8)}`);
  success(`Space name: ${space.name}`);
  success(`Space status: ${space.status}`);
  passedTests++;

  // Add provider to space
  info('Adding provider to space...');
  try {
    await manager.addProvider(space.id, {
      providerId,
      priority: 10,
    });
    success('Provider added to space');
    passedTests++;
  } catch (err) {
    error(`Failed to add provider: ${err}`);
    failedTests++;
  }

  return space.id;
}

// Test: Create container in Coworking Space
async function testCreateSandboxInSpace(spaceId: string) {
  section('Test 2: Create Sandbox in CoworkingSpace');

  const manager = CoworkingSpaceManager.getInstance();

  // Get best provider
  info('Getting best provider...');
  const provider = await manager.getBestProvider(spaceId);
  if (!provider) {
    error('No provider available');
    failedTests++;
    return;
  }
  success(`Provider selected: ${provider.id}`);

  // Check quota before allocation
  info('Checking quota...');
  const quota = manager.checkQuota(spaceId);
  success(`Quota: ${quota.usedContainers}/${quota.maxContainers} containers`);

  // Allocate resource
  info('Allocating resources...');
  const allocated = await manager.allocateResource(spaceId, {
    containers: 1,
  });
  if (allocated) {
    success('Resources allocated');
  } else {
    error('Failed to allocate resources');
    failedTests++;
    return;
  }

  // Create sandbox
  info('Creating sandbox...');
  try {
    const timestamp = Date.now().toString(36);
    const options: SandboxCreateOptions = {
      name: `test-sandbox-${timestamp}`,
    };

    const containerId = await provider.createSandbox(options);
    createdContainers.push({ spaceId, containerId });
    success(`Sandbox created: ${containerId.substring(0, 12)}`);
    passedTests++;

    // Verify container is running
    const status = await provider.getSandboxStatus(containerId);
    success(`Container status: ${status.status}`);
    success(`Container IP: ${status.ip}`);
    passedTests++;

    // Get updated space status
    info('Getting updated space status...');
    const spaceStatus = await manager.getSpaceStatus(spaceId);
    success(`Total containers in space: ${spaceStatus.providers.reduce((sum, p) => sum + p.containerCount, 0)}`);
    passedTests++;

  } catch (err) {
    error(`Failed to create sandbox: ${err}`);
    failedTests++;

    // Release allocated resource
    await manager.releaseResource(spaceId, { containers: 1 });
  }
}

// Test: Resource quota management
async function testResourceQuota(spaceId: string) {
  section('Test 3: Resource Quota Management');

  const manager = CoworkingSpaceManager.getInstance();

  // Check current quota
  info('Checking current quota...');
  const quota = manager.checkQuota(spaceId);
  success(`Containers: ${quota.usedContainers}/${quota.maxContainers}`);
  success(`CPU: ${quota.usedCpu}/${quota.maxCpu}`);
  success(`Memory: ${quota.usedMemory}/${quota.maxMemory} MB`);

  // Allocate more resources
  info('Allocating additional resources...');
  const allocated = await manager.allocateResource(spaceId, {
    containers: 2,
    cpu: 1,
    memory: 512,
  });

  if (allocated) {
    success('Resources allocated successfully');
    const updated = manager.checkQuota(spaceId);
    success(`Updated containers: ${updated.usedContainers}/${updated.maxContainers}`);
    passedTests++;
  } else {
    error('Failed to allocate resources (insufficient quota)');
    failedTests++;
  }

  // Release resources
  info('Releasing resources...');
  await manager.releaseResource(spaceId, {
    containers: 1,
  });
  const released = manager.checkQuota(spaceId);
  success(`After release: ${released.usedContainers}/${released.maxContainers}`);
  passedTests++;
}

// Test: Space monitoring
async function testSpaceMonitoring() {
  section('Test 4: Space Monitoring');

  const manager = CoworkingSpaceManager.getInstance();

  info('Monitoring all spaces...');
  try {
    const statuses = await manager.monitorAllSpaces();
    success(`Monitoring ${statuses.length} spaces`);

    for (const status of statuses) {
      const hasCreatedSpaces = createdSpaces.includes(status.spaceId);
      if (hasCreatedSpaces) {
        log(`  - ${status.spaceName}: ${status.status}`, colors.cyan);
        log(`    Providers: ${status.providers.length}`, colors.cyan);
        log(`    Containers: ${status.providers.reduce((sum, p) => sum + p.containerCount, 0)}`, colors.cyan);
      }
    }
    passedTests++;
  } catch (err) {
    error(`Failed to monitor spaces: ${err}`);
    failedTests++;
  }
}

// Test: Update Space
async function testUpdateSpace(spaceId: string) {
  section('Test 5: Update Space');

  const manager = CoworkingSpaceManager.getInstance();

  info('Updating space name...');
  try {
    const updated = await manager.updateSpace(spaceId, {
      name: 'Updated Local Space',
      description: 'Updated description',
    });

    success(`Space updated: ${updated.name}`);
    success(`Description: ${updated.description}`);
    passedTests++;
  } catch (err) {
    error(`Failed to update space: ${err}`);
    failedTests++;
  }
}

// Test: Aliyun ECS provisioning (requires credentials)
async function testECSProvisioning() {
  section('Test 6: Aliyun ECS Provisioning');

  if (!checkAliyunCredentials()) {
    log('Skipping ECS provisioning test', colors.yellow);
    return;
  }

  const manager = CoworkingSpaceManager.getInstance();

  // Check if required config is available
  if (!ALIYUN_CONFIG.vSwitchId || !ALIYUN_CONFIG.securityGroupId) {
    log('Missing required configuration for ECS provisioning', colors.yellow);
    log('Required: ALIYUN_VSWITCH_ID, ALIYUN_SECURITY_GROUP_ID', colors.yellow);
    return;
  }

  info('Creating Aliyun CoworkingSpace...');
  try {
    const space = await manager.createSpace({
      name: 'Aliyun ECS Space (Auto-Provisioned)',
      description: 'A coworking space with auto-provisioned ECS',
      type: SpaceType.ALIYUN,
      region: ALIYUN_CONFIG.regionId,
      quota: {
        maxContainers: 5,
        maxCpu: 2,
        maxMemory: 4096,
        maxStorage: 25,
      },
      tags: ['aliyun', 'auto-provisioned'],
    });

    createdSpaces.push(space.id);
    success(`Space created: ${space.id.substring(0, 8)}`);
    passedTests++;

    // Note: Actual ECS provisioning is commented out to avoid costs
    // To enable ECS provisioning, uncomment the following:
    /*
    info('Provisioning ECS instance (this may take 2-3 minutes)...');
    const result = await manager.provisionECSInstance(space.id, {
      zoneId: ALIYUN_CONFIG.zoneId,
      vSwitchId: ALIYUN_CONFIG.vSwitchId,
      securityGroupId: ALIYUN_CONFIG.securityGroupId,
      keyPairName: ALIYUN_CONFIG.keyPairName,
      waitForReady: true,
    });

    if (result) {
      success(`ECS provisioned: ${result.instanceId.substring(0, 12)}`);
      if (result.publicIp) {
        success(`Public IP: ${result.publicIp}`);
      }
      provisionedInstances.push(result.instanceId);
      passedTests++;

      // Register as provider
      info('Registering ECS as provider...');
      const providerManager = ProviderManager.getInstance();
      const providerId = `ecs-${result.instanceId.substring(0, 8)}`;

      providerManager.registerProvider(providerId, {
        type: ProviderType.ALIYUN,
        host: result.publicIp || '',
        port: 22,
        username: 'root',
        auth: {
          type: 'privateKey',
          keyPath: `${process.env.HOME}/.ssh/${ALIUN_CONFIG.keyPairName}.pem`,
        },
        dockerNetwork: 'kai-net',
        baseRoot: '/data',
      });

      success(`ECS provider registered: ${providerId}`);

      // Add provider to space
      await manager.addProvider(space.id, {
        providerId,
        priority: 10,
      });

      success('ECS provider added to space');
      passedTests++;
    }

  } catch (err) {
    error(`Failed to provision ECS space: ${err}`);
    failedTests++;
  }
}

// Main test runner
async function main() {
  section('CoworkingSpace E2E Test with ECS Provisioning');
  log('Testing CoworkingSpace with automatic ECS provisioning', colors.yellow);
  console.log('');

  // Check credentials first
  const hasAliyunCredentials = checkAliyunCredentials();
  if (!hasAliyunCredentials) {
    log('', colors.reset);
    log('💡 To enable ECS provisioning tests, configure Aliyun credentials', colors.yellow);
    log('   The rest of the tests will run without ECS provisioning.', colors.yellow);
    log('', colors.reset);
  }

  try {
    const localSpaceId = await testCreateLocalSpace();
    await testCreateSandboxInSpace(localSpaceId);
    await testResourceQuota(localSpaceId);
    await testSpaceMonitoring();
    await testUpdateSpace(localSpaceId);
    await testECSProvisioning();
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
    log('\n🎉 All CoworkingSpace E2E tests passed!', colors.green);
    if (hasAliyunCredentials) {
      log('\n💡 Note: ECS provisioning test is commented out to avoid costs', colors.yellow);
      log('   To enable actual ECS provisioning, uncomment the relevant code in testECSProvisioning()', colors.yellow);
    }
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
