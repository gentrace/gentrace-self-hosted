/**
 * Minimal seed script for self-hosted Gentrace docker-compose-test workflow
 * This creates basic test data for validating the self-hosted setup
 */

import { PrismaClient } from '@prisma/client';
import { fieldEncryptionExtension } from 'prisma-field-encryption';
import * as crypto from 'crypto';

// Generate deterministic UUIDs for testing
function generateTestUuid(input: string): string {
  return crypto.createHash('sha256').update(input).digest('hex').substring(0, 32).replace(/(.{8})(.{4})(.{4})(.{4})(.{12})/, '$1-$2-$3-$4-$5');
}

// Test constants - safe for public repository
const TEST_ORG_ID = generateTestUuid('TestOrg:SelfHosted');
const TEST_USER_ID = generateTestUuid('TestUser:admin@example.com');
const TEST_PIPELINE_ID = generateTestUuid('TestPipeline:Demo');
const TEST_DATASET_ID = generateTestUuid('TestDataset:Demo');
const TEST_API_KEY = 'gen_test_api_key_for_docker_compose_testing_only';
const TEST_API_KEY_ID = generateTestUuid('TestApiKey:' + TEST_API_KEY);

async function main() {
  const prisma = new PrismaClient().$extends(fieldEncryptionExtension());

  console.log('🌱 Starting minimal seed for self-hosted testing...');

  try {
    // Create test organization
    const organization = await prisma.organization.upsert({
      where: { id: TEST_ORG_ID },
      create: {
        id: TEST_ORG_ID,
        name: 'Test Organization',
        slug: 'test-org',
      },
      update: {},
    });
    console.log('✅ Created test organization:', organization.name);

    // Create test user (admin)
    const user = await prisma.user.upsert({
      where: { id: TEST_USER_ID },
      create: {
        id: TEST_USER_ID,
        email: 'admin@example.com',
        name: 'Test Admin',
        emailValidated: true,
        isAdmin: true,
      },
      update: {},
    });
    console.log('✅ Created test user:', user.email);

    // Create test API key for testing
    const apiKey = await prisma.apiKey.upsert({
      where: { id: TEST_API_KEY_ID },
      create: {
        id: TEST_API_KEY_ID,
        key: TEST_API_KEY,
        organizationId: TEST_ORG_ID,
        userId: TEST_USER_ID,
        name: 'Test API Key',
      },
      update: {},
    });
    console.log('✅ Created test API key:', apiKey.name);

    // Create test pipeline
    const pipeline = await prisma.pipeline.upsert({
      where: { id: TEST_PIPELINE_ID },
      create: {
        id: TEST_PIPELINE_ID,
        name: 'Demo Pipeline',
        slug: 'demo-pipeline',
        organizationId: TEST_ORG_ID,
        displayName: 'Demo Pipeline for Testing',
      },
      update: {},
    });
    console.log('✅ Created test pipeline:', pipeline.name);

    // Create test dataset
    const dataset = await prisma.dataset.upsert({
      where: { id: TEST_DATASET_ID },
      create: {
        id: TEST_DATASET_ID,
        name: 'Demo Dataset',
        organizationId: TEST_ORG_ID,
        pipelineId: TEST_PIPELINE_ID,
      },
      update: {},
    });
    console.log('✅ Created test dataset:', dataset.name);

    // Create a simple test case
    const testCase = await prisma.testCase.create({
      data: {
        name: 'Demo Test Case',
        inputs: { query: 'What is 2+2?' },
        expectedOutputs: { answer: '4' },
        datasetId: TEST_DATASET_ID,
        organizationId: TEST_ORG_ID,
      },
    });
    console.log('✅ Created test case:', testCase.name);

    console.log('🎉 Minimal seed completed successfully!');
    console.log('📋 Test data summary:');
    console.log(`   - Organization: ${organization.name} (${organization.id})`);
    console.log(`   - User: ${user.email} (${user.id})`);
    console.log(`   - API Key: ${TEST_API_KEY} (for testing only)`);
    console.log(`   - Pipeline: ${pipeline.name} (${pipeline.id})`);
    console.log(`   - Dataset: ${dataset.name} (${dataset.id})`);
    console.log(`   - Test Case: ${testCase.name} (${testCase.id})`);

  } catch (error) {
    console.error('❌ Error during seeding:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main()
  .catch((e) => {
    console.error('Fatal error:', e);
    process.exit(1);
  });

