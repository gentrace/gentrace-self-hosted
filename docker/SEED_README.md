# Minimal Seed for Self-Hosted Gentrace Testing

This directory contains minimal seed scripts designed for testing the self-hosted Gentrace setup in the `docker-compose-test` GitHub workflow.

## Files

- **`seed-minimal.ts`** - Creates minimal test data for validating the self-hosted setup
- **`test-seed-data.ts`** - Validates that the seed data was created correctly
- **`run-minimal-seed.sh`** - Shell script to run the minimal seed (standalone)
- **`package.json`** - Dependencies for the seed scripts

## What Gets Seeded

The minimal seed creates:

1. **Test Organization** - A basic organization for testing
2. **Test Admin User** - An admin user with email `admin@example.com`
3. **Test API Key** - A safe API key for testing: `gen_test_api_key_for_docker_compose_testing_only`
4. **Test Pipeline** - A demo pipeline for basic functionality testing
5. **Test Dataset** - A demo dataset with one test case
6. **Test Case** - A simple test case with input/output data

## Security Notes

⚠️ **Important**: This seed script is designed for **public repository testing only**. 

- All API keys and credentials are **test-only** and safe for public exposure
- The API key `gen_test_api_key_for_docker_compose_testing_only` is specifically for testing
- No real or sensitive data is included

## Usage in Docker Compose Test

The seed data is automatically created when the main Gentrace app starts via the `npm run self-hosted:migrate-and-seed` command in the docker-compose.yml.

The GitHub workflow validates the seed data using:

```bash
cd docker
npm install
npm run test-seed
```

## Manual Testing

To run the seed manually (for development):

```bash
cd docker
npm install
npm run seed
```

To validate the seed data:

```bash
npm run test-seed
```

## Environment Variables Required

- `DATABASE_URL` - PostgreSQL connection string
- `PRISMA_FIELD_ENCRYPTION_KEY` - Encryption key for Prisma fields

These are automatically set in the docker-compose-test workflow.

## Generated Test IDs

All test data uses deterministic UUIDs generated from SHA256 hashes of descriptive strings. This ensures:

- Consistent test data across runs
- No conflicts with real data
- Easy identification of test vs. real data

Example test IDs:
- Organization: `TestOrg:SelfHosted` → deterministic UUID
- User: `TestUser:admin@example.com` → deterministic UUID
- API Key: `gen_test_api_key_for_docker_compose_testing_only`

