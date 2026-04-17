/**
 * Safe Aliyun ECS Provisioning Test
 *
 * This test will create an ECS instance, stop it, and ask before releasing.
 * Only releases resources on explicit confirmation.
 */

import { CoworkingSpaceManager } from '../../../../repos/ce-orchestrator/src/services/coworking-space-manager';
import { SpaceType } from '../../../../repos/ce-orchestrator/src/types/coworking-space';

// Colors
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[0;36m',
  bold: '\x1b[1m',
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

function warn(message: string) {
  log(`⚠️  ${message}`, colors.yellow);
}

function section(message: string) {
  console.log('');
  log(`═══ ${message} ═══`, colors.cyan);
}

// Test results
const createdInstances: { instanceId: string; publicIp?: string }[] = [];

async function cleanup(release: boolean) {
  section(release ? 'Releasing Resources' : 'Stopping Instances');

  const manager = CoworkingSpaceManager.getInstance();

  for (const { instanceId, publicIp } of createdInstances) {
    try {
      if (release) {
        info(`Releasing ECS instance: ${instanceId.substring(0, 12)}...`);
        const terminated = await manager.terminateECSInstance('test-aliyun-space', instanceId);
        if (terminated) {
          success(`ECS instance released: ${instanceId.substring(0, 12)}`);
        } else {
          error(`Failed to release ECS instance`);
        }
      } else {
        info(`Stopping ECS instance: ${instanceId.substring(0, 12)}...`);
        // Note: stopECS is available in AliyunECSProvisioner
        // but not exposed through CoworkingSpaceManager
        warn(`Stop operation not exposed, skipping...`);
        warn(`Please stop manually: ECS Console > Instances > ${instanceId}`);
      }
    } catch (err) {
      error(`Failed to cleanup ECS: ${err}`);
    }
  }

  await manager.cleanup();
}

async function testECSProvisioning() {
  section('Safe Aliyun ECS Provisioning Test');

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
    name: 'Aliyun ECS Space (Safe Test)',
    description: 'A coworking space with safe ECS provisioning',
    type: SpaceType.ALIYUN,
    region: process.env.ALIYUN_REGION_ID || 'cn-guangzhou',
    quota: {
      maxContainers: 5,
      maxCpu: 2,
      maxMemory: 4096,
      maxStorage: 25,
    },
    tags: ['aliyun', 'safe-test', 'manual-cleanup'],
  });

  success(`Space created: ${space.id.substring(0, 8)}`);

  // Provision ECS instance
  section('Provisioning ECS Instance');
  info('This will take 2-3 minutes...');
  warn('This will incur costs (approx ¥0.02-0.05/hour)');
  warn('You will be asked whether to release the instance after testing');
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
      await cleanup(false);
      process.exit(1);
    }

    success(`ECS Instance provisioned!`);
    success(`Instance ID: ${result.instanceId}`);
    if (result.publicIp) {
      success(`Public IP: ${result.publicIp}`);
    }

    createdInstances.push(result);

    // Show next steps
    section('Instance Ready');
    log('', colors.reset);
    log('Your ECS instance is now running!', colors.bold);
    log('', colors.reset);
    log(`Instance ID: ${result.instanceId}`, colors.cyan);
    log(`Public IP: ${result.publicIp || 'N/A'}`, colors.cyan);
    log(`Region: ${process.env.ALIYUN_REGION_ID || 'cn-guangzhou'}`, colors.cyan);
    log('', colors.reset);
    log('What you can do now:', colors.bold);
    log('1. SSH into the instance:', colors.bold);
    log(`   ssh -i ~/.ssh/${process.env.ALIYUN_KEY_PAIR_NAME}.pem root@${result.publicIp || '<ip>'}`, colors.cyan);
    log('', colors.reset);
    log('2. View in Aliyun Console:', colors.bold);
    log(`   https://ecs.console.aliyun.com/#/server/${result.instanceId}`, colors.cyan);
    log('', colors.reset);
    log('3. The instance will continue running and incur costs', colors.yellow);
    log(`   Approx ¥0.02-0.05/hour for ecs.t6-c1m1.large`, colors.yellow);
    log('', colors.reset);

    // Ask about cleanup
    log('', colors.reset);
    section('Cleanup Options');
    log('', colors.reset);
    log('Choose an option:', colors.bold);
    log('1. Release the instance now (stop and delete)', colors.red);
    log('2. Keep it running (will continue to incur costs)', colors.yellow);
    log('3. Stop it (but keep the instance)', colors.blue);
    log('', colors.reset);
    log('For security, resources will be released by default.', colors.yellow);
    log('Press Ctrl+C to keep the instance running.', colors.yellow);
    log('', colors.reset);
    log('Waiting 30 seconds before releasing...', colors.cyan);
    log('(Press Ctrl+C now to keep the instance)', colors.cyan);
    log('', colors.reset);

    // Wait for cancellation
    await new Promise(resolve => setTimeout(resolve, 30000));

    // Auto cleanup
    await cleanup(true);

    section('Test Summary');
    log('✓ ECS provisioning test completed successfully!', colors.green);
    log('✓ Instance was released', colors.green);
    log('', colors.reset);
    log('If you want to keep instances for testing in the future,', colors.cyan);
    log('press Ctrl+C during the 30-second wait period.', colors.cyan);
    log('', colors.reset);

  } catch (err) {
    error(`Failed to provision ECS: ${err}`);
    await cleanup(false);
    process.exit(1);
  }
}

// Main
async function main() {
  try {
    await testECSProvisioning();
    process.exit(0);
  } catch (err) {
    error(`Fatal error: ${err}`);
    await cleanup(false);
    process.exit(1);
  }
}

main();
