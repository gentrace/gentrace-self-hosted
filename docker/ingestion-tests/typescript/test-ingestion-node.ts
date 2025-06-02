#!/usr/bin/env node

/**
 * TypeScript version of the Gentrace ingestion pipeline test using Gentrace SDK
 *
 * This script tests the full data ingestion pipeline using the Gentrace SDK:
 * 1. Sends OpenTelemetry traces using Gentrace SDK interaction() function
 * 2. Validates data ingestion in Postgres (GTSpan table)
 * 3. Validates data replication to ClickHouse (span table)
 */

import { context, trace } from "@opentelemetry/api";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";
import { BatchSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";
import { ClickHouse } from "clickhouse";
import { init, interaction } from "gentrace";
import { Client } from "pg";
import pino from "pino";

// Create pino logger with pretty printing
const logger = pino({
  transport: {
    target: "pino-pretty",
    options: {
      colorize: true,
      translateTime: "HH:MM:ss",
      ignore: "pid,hostname",
    },
  },
});

// Configuration interface
interface TestConfig {
  gentraceBaseUrl: string;
  postgresHost: string;
  postgresPort: number;
  postgresDb: string;
  postgresUser: string;
  postgresPassword: string;
  clickhouseHost: string;
  clickhousePort: number;
  clickhouseDb: string;
  clickhouseUser: string;
  clickhousePassword: string;
  apiKey: string;
  organizationId: string;
  pipelineId: string;
}

// Database row interfaces
interface PostgresSpanRow {
  id: string;
  traceId: string;
  name: string;
  type: string;
  startTime: Date | null;
  endTime: Date | null;
  attributesMap: Record<string, any> | null;
  sourceOtelSpan: any;
  pipelineId: string;
}

interface ClickHouseSpanRow {
  id: string;
  name: string;
  functionArgs: string;
  functionOutput: string;
  startTime: Date;
  endTime: Date;
  attributesMap: string;
  traceId: string;
  pipelineId: string | null;
}

// Configuration
const config: TestConfig = {
  gentraceBaseUrl: process.env.GENTRACE_BASE_URL || "http://localhost:3000/api",
  postgresHost: process.env.POSTGRES_HOST || "localhost",
  postgresPort: parseInt(process.env.POSTGRES_PORT || "5432"),
  postgresDb: process.env.POSTGRES_DB || "gentrace",
  postgresUser: process.env.POSTGRES_USER || "gentrace",
  postgresPassword: process.env.POSTGRES_PASSWORD || "gentrace123",
  clickhouseHost: process.env.CLICKHOUSE_HOST || "localhost",
  clickhousePort: parseInt(process.env.CLICKHOUSE_PORT || "8123"),
  clickhouseDb: process.env.CLICKHOUSE_DB || "default",
  clickhouseUser: process.env.CLICKHOUSE_USER || "default",
  clickhousePassword: process.env.CLICKHOUSE_PASSWORD || "gentrace123",
  // The default API key is for testing only and is not a security concern.
  apiKey:
    process.env.GENTRACE_API_KEY ||
    "gen_api_x6cPoAJR5Fb63xaTcUcYU1A64PDPUGlppkMDEL2J",
  organizationId: process.env.ORGANIZATION_ID || `test-org-${Date.now()}`,
  pipelineId: process.env.PIPELINE_ID || `c10408c7-abde-5c19-b339-e8b1087c9b64`,
};

class NodeIngestionTester {
  private traceIds: string[] = [];
  private tracer: any;
  private provider: NodeTracerProvider | null = null;

  constructor() {
    this.setupGentrace();
  }

  private setupGentrace(): void {
    logger.info("🔧 Setting up Gentrace SDK and OpenTelemetry...");

    // Initialize Gentrace SDK
    init({
      apiKey: config.apiKey,
      baseURL: config.gentraceBaseUrl,
    });

    // Set up OpenTelemetry as per Gentrace documentation
    const resource = Resource.default().merge(
      new Resource({
        [ATTR_SERVICE_NAME]: "gentrace-ingestion-test-node",
        "service.version": "1.0.0",
      })
    );

    const provider = new NodeTracerProvider({
      resource,
    });

    // Configure OTLP exporter
    const otlpExporter = new OTLPTraceExporter({
      url: `${config.gentraceBaseUrl}/otel/v1/traces`,
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
        "Content-Type": "application/json",
      },
    });

    // Add batch processor with OTLP exporter
    provider.addSpanProcessor(new BatchSpanProcessor(otlpExporter));

    // Register the provider
    provider.register();

    this.provider = provider;
    this.tracer = trace.getTracer("gentrace-test");
    logger.info("✅ Gentrace SDK and OpenTelemetry setup complete");
  }

  // Test functions to be wrapped with interaction()
  private async testInteractionSimple(prompt: string): Promise<string> {
    // Simulate some processing
    await new Promise((resolve) => setTimeout(resolve, 100));
    return `Processed: ${prompt}`;
  }

  private async testLlmCall(
    prompt: string,
    temperature: number = 0.7
  ): Promise<{
    model: string;
    prompt: string;
    temperature: number;
    response: string;
    tokens: number;
  }> {
    // Simulate LLM call
    await new Promise((resolve) => setTimeout(resolve, 100));
    return {
      model: "gpt-4",
      prompt,
      temperature,
      response: `This is a test response to: ${prompt}`,
      tokens: prompt.split(" ").length,
    };
  }

  private async testFunctionWithError(value: number): Promise<number> {
    if (value < 0) {
      throw new Error("Value must be non-negative");
    }
    return value * 2;
  }

  async sendTestTraces(): Promise<string[]> {
    logger.info("📤 Sending test OpenTelemetry traces using Gentrace SDK...");

    // Test 1: Simple interaction using Gentrace SDK
    const tracedSimpleInteraction = interaction(
      "test-interaction",
      this.testInteractionSimple.bind(this),
      {
        pipelineId: config.pipelineId,
        attributes: {
          "test.type": "simple",
          "test.framework": "gentrace-sdk",
        },
      }
    );

    // Execute and capture trace ID
    const span1 = this.tracer.startSpan("capture-trace-1");
    const ctx1 = trace.setSpan(context.active(), span1);
    let result1: string;
    await context.with(ctx1, async () => {
      result1 = await tracedSimpleInteraction("Hello from Gentrace SDK test!");
      const traceId = span1.spanContext().traceId;
      this.traceIds.push(traceId);
      logger.info({
        msg: "✅ Sent simple interaction trace",
        traceId: traceId.substring(0, 8) + "...",
      });
    });
    span1.end();

    // Test 2: LLM call simulation using Gentrace SDK
    const tracedLlmCall = interaction(
      "test-llm-call",
      this.testLlmCall.bind(this),
      {
        pipelineId: config.pipelineId,
        attributes: {
          "test.type": "llm",
          "llm.provider": "openai",
          "llm.model": "gpt-4",
          "test.framework": "gentrace-sdk",
        },
      }
    );

    // Execute and capture trace ID
    const span2 = this.tracer.startSpan("capture-trace-2");
    const ctx2 = trace.setSpan(context.active(), span2);
    let result2: any;
    await context.with(ctx2, async () => {
      result2 = await tracedLlmCall("Generate a haiku about testing", 0.5);
      const traceId = span2.spanContext().traceId;
      this.traceIds.push(traceId);
      logger.info({
        msg: "✅ Sent LLM call trace",
        traceId: traceId.substring(0, 8) + "...",
      });
    });
    span2.end();

    // Test 3: Function with error using Gentrace SDK
    const tracedErrorFunction = interaction(
      "test-exception",
      this.testFunctionWithError.bind(this),
      {
        pipelineId: config.pipelineId,
        attributes: {
          "test.type": "error",
          "test.framework": "gentrace-sdk",
        },
      }
    );

    // Execute with error and capture trace ID
    const span3 = this.tracer.startSpan("capture-trace-3");
    const ctx3 = trace.setSpan(context.active(), span3);
    await context.with(ctx3, async () => {
      try {
        await tracedErrorFunction(-5);
      } catch (error) {
        // Error is automatically recorded by interaction()
      }
      const traceId = span3.spanContext().traceId;
      this.traceIds.push(traceId);
      logger.info({
        msg: "✅ Sent error trace",
        traceId: traceId.substring(0, 8) + "...",
      });
    });
    span3.end();

    logger.info({
      msg: "✅ Sent test traces using Gentrace SDK",
      count: this.traceIds.length,
    });
    return this.traceIds;
  }

  private async connectPostgres(): Promise<Client> {
    const client = new Client({
      host: config.postgresHost,
      port: config.postgresPort,
      database: config.postgresDb,
      user: config.postgresUser,
      password: config.postgresPassword,
    });

    await client.connect();
    return client;
  }

  private async connectClickHouse(): Promise<ClickHouse> {
    const clickhouse = new ClickHouse({
      url: `http://${config.clickhouseHost}`,
      port: config.clickhousePort,
      debug: false,
      basicAuth:
        config.clickhouseUser && config.clickhousePassword
          ? {
              username: config.clickhouseUser,
              password: config.clickhousePassword,
            }
          : null,
      isUseGzip: false,
      format: "json",
    });

    return clickhouse;
  }

  async validatePostgresIngestion(
    traceIds: string[],
    maxWait: number = 30
  ): Promise<boolean> {
    logger.info("🔍 Validating Postgres ingestion...");

    const client = await this.connectPostgres();
    const startTime = Date.now();
    const foundSpans: string[] = [];

    while (Date.now() - startTime < maxWait * 1000) {
      try {
        const result = await client.query<PostgresSpanRow>(
          `
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
                    WHERE "pipelineId" = $1
                    ORDER BY "createdAt" DESC
                    LIMIT 50
                `,
          [config.pipelineId]
        );

        for (const row of result.rows) {
          const {
            id,
            traceId,
            name,
            type,
            startTime,
            endTime,
            attributesMap,
            sourceOtelSpan,
            pipelineId,
          } = row;

          // Check if this span has test attributes
          if (
            attributesMap &&
            attributesMap.test &&
            attributesMap.test.framework === "gentrace-sdk"
          ) {
            foundSpans.push(name);
            logger.info({
              msg: "✅ Found span",
              name,
              type,
              traceId: traceId.substring(0, 8) + "...",
            });

            // Validate required fields
            if (!startTime || !endTime) {
              logger.warn("    ⚠️  Missing timestamps");
            }
            if (!attributesMap || Object.keys(attributesMap).length === 0) {
              logger.warn("    ⚠️  Missing attributes");
            }
            if (pipelineId !== config.pipelineId) {
              logger.warn({
                msg: "    ⚠️  Pipeline ID mismatch",
                pipelineId,
              });
            }
          }
        }

        // Check if we found all expected spans
        const foundSpanNames = foundSpans.join(" ");
        if (
          foundSpanNames.includes("test-interaction") &&
          foundSpanNames.includes("test-llm-call") &&
          foundSpanNames.includes("test-exception")
        ) {
          break;
        }

        await new Promise((resolve) => setTimeout(resolve, 1000));
      } catch (error: any) {
        logger.error({
          msg: "❌ Error querying Postgres",
          error: error.message,
        });
        break;
      }
    }

    await client.end();

    const success = foundSpans.length >= 3;
    if (success) {
      logger.info({
        msg: "✅ Postgres validation successful",
        spanCount: foundSpans.length,
      });
    } else {
      logger.error({
        msg: "❌ Postgres validation failed",
        spanCount: foundSpans.length,
      });
    }

    return success;
  }

  async validateClickHouseReplication(
    traceIds: string[],
    maxWait: number = 120
  ): Promise<boolean> {
    logger.info("🔍 Validating ClickHouse replication...");
    logger.info(
      "   Note: ClickHouse replication is eventually consistent, allowing extra time..."
    );

    const clickhouse = await this.connectClickHouse();
    const startTime = Date.now();
    let foundSpans = 0;

    // Add initial settling time for eventual consistency
    logger.info(
      "   ⏳ Waiting 2 seconds for ClickHouse replication to settle..."
    );
    await new Promise((resolve) => setTimeout(resolve, 2_000));

    while (Date.now() - startTime < maxWait * 1000) {
      try {
        const query = `
                    SELECT 
                        id,
                        name,
                        functionArgs,
                        functionOutput,
                        startTime,
                        endTime,
                        attributesMap,
                        traceId,
                        pipelineId
                    FROM GTSpan 
                    WHERE pipelineId = '${config.pipelineId}'
                    ORDER BY createdAt DESC
                    LIMIT 50
                `;

        const result = await clickhouse.query(query).toPromise();

        logger.debug({
          msg: "ClickHouse query result",
          result: JSON.stringify(result, null, 2),
        });

        foundSpans = 0;
        for (const row of result as ClickHouseSpanRow[]) {
          const {
            id,
            name,
            functionArgs,
            functionOutput,
            startTime,
            endTime,
            attributesMap,
            traceId,
            pipelineId,
          } = row;

          // Parse attributesMap if it's a JSON string
          let attributes: any = {};
          if (attributesMap) {
            try {
              attributes = JSON.parse(attributesMap);
            } catch {
              // If parsing fails, treat as empty
            }
          }

          // Check if this span is from our test
          if (attributes.test && attributes.test.framework === "gentrace-sdk") {
            foundSpans++;
            logger.info({
              msg: "✅ Found ClickHouse span",
              name,
              id: id.substring(0, 8) + "...",
            });

            // Validate data structure
            if (functionArgs) {
              try {
                JSON.parse(functionArgs);
                logger.info("    ✅ Valid functionArgs JSON");
              } catch {
                logger.warn("    ⚠️  Invalid functionArgs JSON");
              }
            }

            if (functionOutput) {
              try {
                JSON.parse(functionOutput);
                logger.info("    ✅ Valid functionOutput JSON");
              } catch {
                logger.warn("    ⚠️  Invalid functionOutput JSON");
              }
            }
          }
        }

        if (foundSpans >= 3) {
          break;
        }

        await new Promise((resolve) => setTimeout(resolve, 2000));
      } catch (error: any) {
        logger.error({
          msg: "❌ Error querying ClickHouse",
          error: error.message,
        });
        break;
      }
    }

    const success = foundSpans >= 3;
    if (success) {
      logger.info({
        msg: "✅ ClickHouse validation successful",
        spanCount: foundSpans,
      });
    } else {
      logger.error({
        msg: "❌ ClickHouse validation failed",
        spanCount: foundSpans,
      });
    }

    return success;
  }

  async runFullTest(): Promise<boolean> {
    logger.info(
      "🚀 Starting Gentrace ingestion pipeline test (Node.js with Gentrace SDK)"
    );
    logger.info({
      msg: "Configuration",
      baseUrl: config.gentraceBaseUrl,
      postgres: `${config.postgresHost}:${config.postgresPort}`,
      clickHouse: `${config.clickhouseHost}:${config.clickhousePort}`,
      pipelineId: config.pipelineId,
    });

    // Step 1: Send test traces
    let traceIds: string[];
    try {
      traceIds = await this.sendTestTraces();
    } catch (error: any) {
      logger.error({
        msg: "❌ Failed to send test traces",
        error: error.message,
      });
      return false;
    }

    // Step 2: Validate Postgres ingestion
    const postgresSuccess = await this.validatePostgresIngestion(traceIds);

    // Step 3: Validate ClickHouse replication
    const clickhouseSuccess = await this.validateClickHouseReplication(
      traceIds
    );

    // Summary
    logger.info("\n📊 Test Results Summary:");
    logger.info(`   Trace Sending: ✅`);
    logger.info(`   Postgres Ingestion: ${postgresSuccess ? "✅" : "❌"}`);
    logger.info(
      `   ClickHouse Replication: ${clickhouseSuccess ? "✅" : "❌"}`
    );

    const overallSuccess = postgresSuccess && clickhouseSuccess;

    if (overallSuccess) {
      logger.info(
        "\n🎉 All tests passed! Ingestion pipeline is working correctly."
      );
    } else {
      logger.error("\n💥 Some tests failed. Check the logs above for details.");
    }

    return overallSuccess;
  }
}

async function main(): Promise<void> {
  logger.info("Gentrace Self-Hosted Ingestion Pipeline Test (Node.js)");
  logger.info("=".repeat(60));

  const tester = new NodeIngestionTester();

  // Set up beforeExit handler to ensure traces are flushed
  process.on("beforeExit", async () => {
    const provider = trace.getTracerProvider() as NodeTracerProvider;
    if (provider && provider.forceFlush) {
      logger.info("⏳ Flushing traces before exit...");
      await provider.forceFlush();
      logger.info("✅ Traces flushed");
    }
  });

  const success = await tester.runFullTest();

  process.exit(success ? 0 : 1);
}

if (require.main === module) {
  main().catch((error) => {
    logger.error({
      msg: "❌ Test failed with error",
      error: error,
    });
    process.exit(1);
  });
}
