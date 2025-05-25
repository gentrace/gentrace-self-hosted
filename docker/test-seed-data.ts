/**
 * Test script to validate that the minimal seed data was created correctly
 * This can be used in the docker-compose-test workflow to verify the setup
 */

import { PrismaClient } from '@prisma/client';
import { fieldEncryptionExtension } from 'prisma-field-encryption';
import * as crypto from 'crypto';

// Generate deterministic UUIDs for testing (same as seed script)
function generateTestUuid(input: string): string {
  return crypto.createHash('sha256').update(input).digest('hex').substring(0, 32).replace(/(.{8})(.{4})(.{4})(.{4})(.{12})/, '$1-$2-$3-$4-$5');
}

// Test constants - must match seed script
const TEST_ORG_ID = generateTestUuid('TestOrg:SelfHosted');
const TEST_USER_ID = generateTestUuid('TestUser:admin@example.com');
const TEST_PIPELINE_ID = generateTestUuid('TestPipeline:Demo');
const TEST_DATASET_ID = generateTestUuid('TestDataset:Demo');
const TEST_API_KEY = 'gen_test_api_key_for_docker_compose_testing_only';

async function validateSeedData() {
  const prisma = new PrismaClient().$extends(fieldEncryptionExtension());

  console.log('🔍 Validating minimal seed data...');

  try {
    // Check organization exists
    const organization = await prisma.organization.findUnique({
      where: { id: TEST_ORG_ID },
    });
    if (!organization) {
      throw new Error('Test organization not found');
    }
    console.log('✅ Organization found:', organization.name);

    // Check user exists
    const user = await prisma.user.findUnique({
      where: { id: TEST_USER_ID },
    });
    if (!user) {
      throw new Error('Test user not found');
    }
    console.log('✅ User found:', user.email);

    // Check API key exists
    const apiKey = await prisma.apiKey.findFirst({
      where: { key: TEST_API_KEY },
    });
    if (!apiKey) {
      throw new Error('Test API key not found');
    }
    console.log('✅ API key found:', apiKey.name);

    // Check pipeline exists
    const pipeline = await prisma.pipeline.findUnique({
      where: { id: TEST_PIPELINE_ID },
    });
    if (!pipeline) {
      throw new Error('Test pipeline not found');
    }
    console.log('✅ Pipeline found:', pipeline.name);

    // Check dataset exists
    const dataset = await prisma.dataset.findUnique({
      where: { id: TEST_DATASET_ID },
    });
    if (!dataset) {
      throw new Error('Test dataset not found');
    }
    console.log('✅ Dataset found:', dataset.name);

    // Check test case exists
    const testCase = await prisma.testCase.findFirst({
      where: { datasetId: TEST_DATASET_ID },
    });
    if (!testCase) {
      throw new Error('Test case not found');
    }
    console.log('✅ Test case found:', testCase.name);

    // Validate data integrity
    if (organization.id !== TEST_ORG_ID) {
      throw new Error('Organization ID mismatch');
    }
    if (user.organizationId && user.organizationId !== TEST_ORG_ID) {
      throw new Error('User organization mismatch');
    }
    if (apiKey.organizationId !== TEST_ORG_ID) {
      throw new Error('API key organization mismatch');
    }
    if (pipeline.organizationId !== TEST_ORG_ID) {
      throw new Error('Pipeline organization mismatch');
    }
    if (dataset.organizationId !== TEST_ORG_ID) {
      throw new Error('Dataset organization mismatch');
    }

    console.log('🎉 All seed data validation passed!');
    console.log('📊 Summary:');
    console.log(`   - Organization: ${organization.name}`);
    console.log(`   - User: ${user.email} (Admin: ${user.isAdmin})`);
    console.log(`   - API Key: ${apiKey.name}`);
    console.log(`   - Pipeline: ${pipeline.name}`);
    console.log(`   - Dataset: ${dataset.name}`);
    console.log(`   - Test Cases: 1 found`);

    return true;

  } catch (error) {
    console.error('❌ Validation failed:', error);
    return false;
  } finally {
    await prisma.$disconnect();
  }
}

async function main() {
  const success = await validateSeedData();
  process.exit(success ? 0 : 1);
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});

