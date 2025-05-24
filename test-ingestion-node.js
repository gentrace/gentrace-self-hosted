#!/usr/bin/env node

/**
 * Node.js version of the Gentrace ingestion pipeline test
 * 
 * This script tests the full data ingestion pipeline using the Node.js OpenTelemetry SDK:
 * 1. Sends OpenTelemetry traces to the OTEL endpoint
 * 2. Validates data ingestion in Postgres (GTSpan table)
 * 3. Validates data replication to ClickHouse (span table)
 */

const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { ATTR_SERVICE_NAME } = require('@opentelemetry/semantic-conventions');
const { trace, SpanStatusCode } = require('@opentelemetry/api');
const { Client } = require('pg');
const { ClickHouse } = require('clickhouse');
const axios = require('axios');

// Configuration
const config = {
    gentraceBaseUrl: process.env.GENTRACE_BASE_URL || 'http://localhost:3000',
    postgresHost: process.env.POSTGRES_HOST || 'localhost',
    postgresPort: parseInt(process.env.POSTGRES_PORT) || 5432,
    postgresDb: process.env.POSTGRES_DB || 'gentrace',
    postgresUser: process.env.POSTGRES_USER || 'postgres',
    postgresPassword: process.env.POSTGRES_PASSWORD || 'password',
    clickhouseHost: process.env.CLICKHOUSE_HOST || 'localhost',
    clickhousePort: parseInt(process.env.CLICKHOUSE_PORT) || 8123,
    clickhouseDb: process.env.CLICKHOUSE_DB || 'default',
    clickhouseUser: process.env.CLICKHOUSE_USER || 'default',
    clickhousePassword: process.env.CLICKHOUSE_PASSWORD || '',
    apiKey: process.env.GENTRACE_API_KEY || `gt-test-${Date.now()}`,
    organizationId: process.env.ORGANIZATION_ID || `test-org-${Date.now()}`,
    pipelineId: process.env.PIPELINE_ID || `test-pipeline-${Date.now()}`
};

class NodeIngestionTester {
    constructor() {
        this.traceIds = [];
        this.setupOTel();
    }

    setupOTel() {
        console.log('🔧 Setting up OpenTelemetry...');
        
        const sdk = new NodeSDK({
            resource: new Resource({
                [ATTR_SERVICE_NAME]: 'gentrace-ingestion-test-node',
                'service.version': '1.0.0'
            }),
            traceExporter: new OTLPTraceExporter({
                url: `${config.gentraceBaseUrl}/api/otel/v1/traces`,
                headers: {
                    'Authorization': `Bearer ${config.apiKey}`,
                    'Content-Type': 'application/x-protobuf'
                }
            })
        });

        sdk.start();
        this.tracer = trace.getTracer('gentrace-test');
        console.log('✅ OpenTelemetry setup complete');
    }

    async sendTestTraces() {
        console.log('📤 Sending test OpenTelemetry traces...');
        
        // Test trace 1: Simple interaction
        await this.tracer.startActiveSpan('test-interaction-node', async (span) => {
            span.setAttributes({
                'gentrace.pipeline_id': config.pipelineId,
                'gentrace.sample': 'true',
                'gentrace.type': 'interaction',
                'function.name': 'test_function_node',
                'function.args': JSON.stringify(['arg1', 'arg2']),
                'function.output': JSON.stringify({ result: 'test output from node' })
            });
            
            const traceId = span.spanContext().traceId;
            this.traceIds.push(traceId);
            
            // Simulate some work
            await new Promise(resolve => setTimeout(resolve, 100));
            span.end();
        });

        // Test trace 2: LLM call
        await this.tracer.startActiveSpan('test-llm-call-node', async (span) => {
            span.setAttributes({
                'gentrace.pipeline_id': config.pipelineId,
                'gentrace.sample': 'true',
                'gentrace.type': 'llm',
                'llm.provider': 'openai',
                'llm.model': 'gpt-4',
                'llm.messages': JSON.stringify([
                    { role: 'user', content: 'Hello from Node.js test!' }
                ]),
                'llm.choices': JSON.stringify([
                    { message: { role: 'assistant', content: 'Hello! This is a Node.js test response.' } }
                ])
            });
            
            const traceId = span.spanContext().traceId;
            this.traceIds.push(traceId);
            
            await new Promise(resolve => setTimeout(resolve, 100));
            span.end();
        });

        // Test trace 3: Exception/error
        await this.tracer.startActiveSpan('test-exception-node', async (span) => {
            span.setAttributes({
                'gentrace.pipeline_id': config.pipelineId,
                'gentrace.sample': 'true',
                'gentrace.type': 'function'
            });
            
            const traceId = span.spanContext().traceId;
            this.traceIds.push(traceId);
            
            // Simulate an exception
            try {
                throw new Error('Test exception from Node.js for ingestion testing');
            } catch (error) {
                span.recordException(error);
                span.setStatus({ code: SpanStatusCode.ERROR, message: 'Test error' });
            }
            
            span.end();
        });

        // Force flush
        await trace.getTracerProvider().forceFlush();
        
        console.log(`✅ Sent ${this.traceIds.length} test traces`);
        return this.traceIds;
    }

    async connectPostgres() {
        const client = new Client({
            host: config.postgresHost,
            port: config.postgresPort,
            database: config.postgresDb,
            user: config.postgresUser,
            password: config.postgresPassword
        });
        
        await client.connect();
        return client;
    }

    async connectClickHouse() {
        const clickhouse = new ClickHouse({
            url: `http://${config.clickhouseHost}`,
            port: config.clickhousePort,
            debug: false,
            basicAuth: config.clickhouseUser && config.clickhousePassword ? {
                username: config.clickhouseUser,
                password: config.clickhousePassword
            } : null,
            isUseGzip: false,
            format: "json"
        });
        
        return clickhouse;
    }

    async validatePostgresIngestion(traceIds, maxWait = 30) {
        console.log('🔍 Validating Postgres ingestion...');
        
        const client = await this.connectPostgres();
        const startTime = Date.now();
        const foundTraces = new Set();
        
        while (Date.now() - startTime < maxWait * 1000) {
            try {
                const result = await client.query(`
                    SELECT 
                        id, 
                        "traceId", 
                        name, 
                        type, 
                        "startTime", 
                        "endTime",
                        "attributesMap",
                        "sourceOtelSpan",
                        "pipelineId"
                    FROM "GTSpan" 
                    WHERE "organizationId" = $1
                    ORDER BY "createdAt" DESC
                    LIMIT 50
                `, [config.organizationId]);
                
                for (const row of result.rows) {
                    const { id, traceId, name, type, startTime, endTime, attributesMap, sourceOtelSpan, pipelineId } = row;
                    
                    // Check if this is one of our test traces
                    if (traceIds.some(tid => traceId.includes(tid))) {
                        foundTraces.add(traceId);
                        console.log(`  ✅ Found span: ${name} (type: ${type}, trace: ${traceId.substring(0, 8)}...)`);
                        
                        // Validate required fields
                        if (!startTime || !endTime) {
                            console.log(`    ⚠️  Missing timestamps`);
                        }
                        if (!attributesMap || Object.keys(attributesMap).length === 0) {
                            console.log(`    ⚠️  Missing attributes`);
                        }
                        if (sourceOtelSpan === 'null') {
                            console.log(`    ⚠️  Missing sourceOtelSpan`);
                        }
                        if (pipelineId !== config.pipelineId) {
                            console.log(`    ⚠️  Pipeline ID mismatch: ${pipelineId}`);
                        }
                    }
                }
                
                if (foundTraces.size >= traceIds.length) {
                    break;
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
                
            } catch (error) {
                console.log(`❌ Error querying Postgres: ${error.message}`);
                break;
            }
        }
        
        await client.end();
        
        const success = foundTraces.size >= traceIds.length;
        if (success) {
            console.log(`✅ Postgres validation successful: ${foundTraces.size}/${traceIds.length} traces found`);
        } else {
            console.log(`❌ Postgres validation failed: ${foundTraces.size}/${traceIds.length} traces found`);
        }
        
        return success;
    }

    async validateClickHouseReplication(traceIds, maxWait = 60) {
        console.log('🔍 Validating ClickHouse replication...');
        
        const clickhouse = await this.connectClickHouse();
        const startTime = Date.now();
        let foundSpans = 0;
        
        while (Date.now() - startTime < maxWait * 1000) {
            try {
                const query = `
                    SELECT 
                        id,
                        name,
                        inputs,
                        outputs,
                        startTime,
                        endTime,
                        metadata,
                        runId
                    FROM span 
                    WHERE createdAt >= now() - INTERVAL 5 MINUTE
                    ORDER BY createdAt DESC
                    LIMIT 50
                `;
                
                const result = await clickhouse.query(query).toPromise();
                
                foundSpans = 0;
                for (const row of result) {
                    const { id, name, inputs, outputs, startTime, endTime, metadata, runId } = row;
                    
                    // Check if this span is related to our test
                    if (traceIds.some(tid => id.includes(tid)) || name.toLowerCase().includes('test') || name.toLowerCase().includes('node')) {
                        foundSpans++;
                        console.log(`  ✅ Found ClickHouse span: ${name} (id: ${id.substring(0, 8)}...)`);
                        
                        // Validate data structure
                        if (inputs) {
                            try {
                                JSON.parse(inputs);
                                console.log(`    ✅ Valid inputs JSON`);
                            } catch {
                                console.log(`    ⚠️  Invalid inputs JSON`);
                            }
                        }
                        
                        if (outputs) {
                            try {
                                JSON.parse(outputs);
                                console.log(`    ✅ Valid outputs JSON`);
                            } catch {
                                console.log(`    ⚠️  Invalid outputs JSON`);
                            }
                        }
                    }
                }
                
                if (foundSpans > 0) {
                    break;
                }
                
                await new Promise(resolve => setTimeout(resolve, 2000));
                
            } catch (error) {
                console.log(`❌ Error querying ClickHouse: ${error.message}`);
                break;
            }
        }
        
        const success = foundSpans > 0;
        if (success) {
            console.log(`✅ ClickHouse validation successful: ${foundSpans} spans found`);
        } else {
            console.log(`❌ ClickHouse validation failed: no spans found`);
        }
        
        return success;
    }

    async testApiEndpointHealth() {
        console.log('🏥 Testing API endpoint health...');
        
        try {
            const response = await axios.get(`${config.gentraceBaseUrl}/api/health`, { timeout: 10000 });
            if (response.status === 200) {
                console.log('✅ API endpoint is accessible');
                return true;
            } else {
                console.log(`⚠️  API endpoint returned status ${response.status}`);
                return false;
            }
        } catch (error) {
            console.log(`❌ API endpoint health check failed: ${error.message}`);
            return false;
        }
    }

    async runFullTest() {
        console.log('🚀 Starting Gentrace ingestion pipeline test (Node.js)');
        console.log(`   Base URL: ${config.gentraceBaseUrl}`);
        console.log(`   Postgres: ${config.postgresHost}:${config.postgresPort}`);
        console.log(`   ClickHouse: ${config.clickhouseHost}:${config.clickhousePort}`);
        console.log();
        
        // Step 1: Test API health
        if (!(await this.testApiEndpointHealth())) {
            return false;
        }
        
        // Step 2: Send test traces
        let traceIds;
        try {
            traceIds = await this.sendTestTraces();
        } catch (error) {
            console.log(`❌ Failed to send test traces: ${error.message}`);
            return false;
        }
        
        // Step 3: Validate Postgres ingestion
        const postgresSuccess = await this.validatePostgresIngestion(traceIds);
        
        // Step 4: Validate ClickHouse replication
        const clickhouseSuccess = await this.validateClickHouseReplication(traceIds);
        
        // Summary
        console.log('\n📊 Test Results Summary:');
        console.log(`   API Health: ✅`);
        console.log(`   Trace Sending: ✅`);
        console.log(`   Postgres Ingestion: ${postgresSuccess ? '✅' : '❌'}`);
        console.log(`   ClickHouse Replication: ${clickhouseSuccess ? '✅' : '❌'}`);
        
        const overallSuccess = postgresSuccess && clickhouseSuccess;
        
        if (overallSuccess) {
            console.log('\n🎉 All tests passed! Ingestion pipeline is working correctly.');
        } else {
            console.log('\n💥 Some tests failed. Check the logs above for details.');
        }
        
        return overallSuccess;
    }
}

async function main() {
    console.log('Gentrace Self-Hosted Ingestion Pipeline Test (Node.js)');
    console.log('='.repeat(60));
    
    const tester = new NodeIngestionTester();
    const success = await tester.runFullTest();
    
    process.exit(success ? 0 : 1);
}

if (require.main === module) {
    main().catch(error => {
        console.error('❌ Test failed with error:', error);
        process.exit(1);
    });
}

