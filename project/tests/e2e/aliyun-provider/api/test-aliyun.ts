/**
 * Test script for Aliyun Provider connection
 */

import { ProviderManager } from './src/providers/ProviderManager';
import { loadProviderConfig } from './src/providers/configLoader';

async function testAliyunConnection() {
  console.log('=== Testing Aliyun ECS Provider Connection ===\n');

  try {
    // 1. Load configuration
    console.log('1. Loading configuration from ~/.config/ce-orchestrator/providers.yaml');
    const config = await loadProviderConfig(`${process.env.HOME}/.config/ce-orchestrator/providers.yaml`);
    console.log('   ✓ Configuration loaded');
    console.log(`   Providers: ${Object.keys(config.providers).join(', ')}\n`);

    // 2. Initialize ProviderManager
    console.log('2. Initializing ProviderManager');
    const manager = ProviderManager.getInstance();
    console.log('   ✓ ProviderManager initialized\n');

    // 3. Register provider
    console.log('3. Registering Aliyun provider');
    const providerId = 'aliyun-prod';
    manager.registerProvider(providerId, config.providers[providerId]);
    console.log(`   ✓ Provider "${providerId}" registered\n`);

    // 4. Test connection
    console.log('4. Testing SSH connection to 8.134.76.139...');
    const connected = await manager.testProvider(providerId);
    if (connected) {
      console.log('   ✓ Connection successful!\n');
    } else {
      console.log('   ✗ Connection failed\n');
      return;
    }

    // 5. List sandboxes
    console.log('5. Listing sandboxes on Aliyun ECS...');
    const sandboxes = await manager.listAllSandboxes();
    console.log(`   Found ${sandboxes.length} sandbox(es):\n`);

    if (sandboxes.length === 0) {
      console.log('   No sandboxes found. You may need to create containers on the ECS instance first.');
    } else {
      sandboxes.forEach((sandbox, index) => {
        console.log(`   ${index + 1}. ${sandbox.name} (${sandbox.id})`);
        console.log(`      Status: ${sandbox.status}`);
        console.log(`      Provider: ${sandbox.provider}`);
        if (sandbox.containerName) {
          console.log(`      Container: ${sandbox.containerName}`);
        }
        console.log('');
      });
    }

    console.log('=== Test Complete ===');

  } catch (error) {
    console.error('\n✗ Error:', error instanceof Error ? error.message : String(error));
    console.error('\nTroubleshooting tips:');
    console.error('- Check if SSH key exists: ls -la ~/.ssh/aliyun_key');
    console.error('- Test SSH manually: ssh -i ~/.ssh/aliyun_key root@8.134.76.139');
    console.error('- Verify Docker is running on ECS: docker ps');
    console.error('- Check network connectivity: ping 8.134.76.139');
  }
}

testAliyunConnection();
