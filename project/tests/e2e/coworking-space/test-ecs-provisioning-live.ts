/**
 * Live Aliyun ECS Provisioning Test
 *
 * This test will ACTUALLY create an ECS instance and incur costs.
 * Only run this when you have valid Aliyun credentials configured.
 */

import { CoworkingSpaceManager } from '../../../../repos/ce-orchestrator/src/services/coworking-space-manager';
import { ProviderManager } from '../../../../repos/ce-orchestrator/src/providers/ProviderManager';
import { SpaceType } from '../../../../repos/ce-orchestrator/src/types/coworking-space';
import { ProviderType } from '../../../../repos/ce-orchestrator/src/providers/types';

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

// Provisioned instances for cleanup
const provisionedInstances: string[] = [];

async function cleanup() {
  section('Cleanup');
  const manager = CoworkingSpaceManager.getInstance();

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

  await manager.cleanup();
}

async function testECSProvisioning() {
  section('Live Aliyun ECS Provisioning Test');

  const manager = CoworkingSpaceManager.getInstance();

  // Check credentials
  if (!process.env.ALIYUN_ACCESS_KEY_ID || !process.env.ALIYUN_ACCESS_KEY_SECRET) {
    error('Aliyun credentials not configured');
    log('Please set ALIYUN_ACCESS_KEY_ID and ALIYUN_ACCESS_KEY_SECRET', colors.yellow);
    process.exit(1);
  }

  // Check required config
  const vSwitchId = process.env.ALIYUN_VSWITCH_ID;
  const securityGroupId = process.env.ALIYUN_SECURITY_GROUP_ID;

  if (!vSwitchId || !securityGroupId) {
    error('Missing required configuration');
    log('Please set ALIYUN_VSWITCH_ID and ALIYUN_SECURITY_GROUP_ID', colors.yellow);
    process.exit(1);
  }

  success(`Credentials configured`);
  success(`VSwitch: ${vSwitchId}`);
  success(`Security Group: ${securityGroupId}`);

  // Create Aliyun CoworkingSpace
  info('Creating Aliyun CoworkingSpace...');
  const space = await manager.createSpace({
    name: 'Aliyun ECS Space (Live Test)',
    description: 'A coworking space with live-provisioned ECS',
    type: SpaceType.ALIYUN,
    region: process.env.ALIYUN_REGION_ID || 'cn-guangzhou',
    quota: {
      maxContainers: 5,
      maxCpu: 2,
      maxMemory: 4096,
      maxStorage: 25,
    },
    tags: ['aliyun', 'live-test', 'provisioned'],
  });

  success(`Space created: ${space.id.substring(0, 8)}`);

  // Provision ECS instance
  section('Provisioning ECS Instance');
  info('This will take 2-3 minutes...');
  log('⚠️  This will incur costs (approx ¥0.02-0.05/hour)', colors.yellow);
  log('');

  try {
    const result = await manager.provisionECSInstance(space.id, {
      vSwitchId,
      securityGroupId,
      keyPairName: process.env.ALIYUN_KEY_PAIR_NAME,
      waitForReady: true,
    });

    if (!result) {
      error('Failed to provision ECS instance');
      await cleanup();
      process.exit(1);
    }

    success(`ECS Instance provisioned!`);
    success(`Instance ID: ${result.instanceId}`);
    if (result.publicIp) {
      success(`Public IP: ${result.publicIp}`);
    }

    provisionedInstances.push(result.instanceId);

    // Wait a bit before cleanup
    section('Verification');
    info('Waiting 10 seconds before cleanup...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    success(`ECS instance is running and ready to use!`);

  } catch (err) {
    error(`Failed to provision ECS: ${err}`);
    await cleanup();
    process.exit(1);
  }

  await cleanup();

  section('Test Summary');
  log('✓ ECS provisioning test completed successfully!', colors.green);
  log('✓ Instance was created and terminated', colors.green);
  log('', colors.reset);
  log('Next steps:', colors.cyan);
  log('1. Check Aliyun Console to verify the instance', colors.cyan);
  log('2. The instance should be in "Stopped" or "Released" state', colors.cyan);
  log('3. You can manually release it if needed', colors.cyan);
}

// Main
async function main() {
  try {
    await testECSProvisioning();
    process.exit(0);
  } catch (err) {
    error(`Fatal error: ${err}`);
    await cleanup();
    process.exit(1);
  }
}

main();
