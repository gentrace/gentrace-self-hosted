#!/usr/bin/env python3
"""
Comprehensive test for Gentrace self-hosted container setup using Gentrace SDK.

This script tests the full data ingestion pipeline:
1. Sends OpenTelemetry traces using Gentrace SDK interaction() function
2. Validates data ingestion in Postgres (GTSpan table)
3. Validates data replication to ClickHouse (span table)
"""

import asyncio
import json
import os
import sys
import time
from dataclasses import dataclass
from typing import Any, Dict, List

import clickhouse_driver  # type: ignore
import requests  # type: ignore

# Import Gentrace SDK
import gentrace
import psycopg2  # type: ignore

# OpenTelemetry imports for setup
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


@dataclass
class TestConfig:
    """Configuration for the ingestion test."""
    gentrace_base_url: str = "http://localhost:3000/api"
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "gentrace"
    postgres_user: str = "gentrace"
    postgres_password: str = "gentrace123"
    clickhouse_host: str = "localhost"
    clickhouse_port: int = 8123
    clickhouse_db: str = "default"
    clickhouse_user: str = "default"
    clickhouse_password: str = "gentrace123"
    # The default API key is for testing only and is not a security concern.
    api_key: str = "gen_api_x6cPoAJR5Fb63xaTcUcYU1A64PDPUGlppkMDEL2J"
    organization_id: str = "test-org-id"
    pipeline_id: str = "c10408c7-abde-5c19-b339-e8b1087c9b64"
    
    @classmethod
    def from_env(cls) -> 'TestConfig':
        """Create config from environment variables."""
        return cls(
            gentrace_base_url=os.getenv("GENTRACE_BASE_URL", cls.gentrace_base_url),
            postgres_host=os.getenv("POSTGRES_HOST", cls.postgres_host),
            postgres_port=int(os.getenv("POSTGRES_PORT", str(cls.postgres_port))),
            postgres_db=os.getenv("POSTGRES_DB", cls.postgres_db),
            postgres_user=os.getenv("POSTGRES_USER", cls.postgres_user),
            postgres_password=os.getenv("POSTGRES_PASSWORD", cls.postgres_password),
            clickhouse_host=os.getenv("CLICKHOUSE_HOST", cls.clickhouse_host),
            clickhouse_port=int(os.getenv("CLICKHOUSE_PORT", str(cls.clickhouse_port))),
            clickhouse_db=os.getenv("CLICKHOUSE_DB", cls.clickhouse_db),
            clickhouse_user=os.getenv("CLICKHOUSE_USER", cls.clickhouse_user),
            clickhouse_password=os.getenv("CLICKHOUSE_PASSWORD", cls.clickhouse_password),
            api_key=os.getenv("GENTRACE_API_KEY", cls.api_key),
            organization_id=os.getenv("ORGANIZATION_ID", cls.organization_id),
            pipeline_id=os.getenv("PIPELINE_ID", cls.pipeline_id),
        )


class IngestionTester:
    """Tests the full Gentrace ingestion pipeline."""
    
    def __init__(self, config: TestConfig):
        self.config = config
        self.trace_ids: List[str] = []
        self.setup_gentrace()
        
    def setup_gentrace(self):
        """Set up Gentrace SDK and OpenTelemetry."""
        # Initialize Gentrace SDK
        gentrace.init(
            api_key=self.config.api_key,
            base_url=self.config.gentrace_base_url,
        )
        
        # Set up OpenTelemetry as per Gentrace documentation
        resource = Resource.create({
            "service.name": "gentrace-ingestion-test",
            "service.version": "1.0.0",
        })
        
        tracer_provider = TracerProvider(
            resource=resource,
        )
        
        # Configure OTLP exporter
        otlp_exporter = OTLPSpanExporter(
            endpoint=f"{self.config.gentrace_base_url}/otel/v1/traces",
            headers={
                "Authorization": f"Bearer {self.config.api_key}",
                "Content-Type": "application/json"
            }
        )
        
        # Add Gentrace span processor
        tracer_provider.add_span_processor(gentrace.GentraceSpanProcessor())
        tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
        
        trace.set_tracer_provider(tracer_provider)
    
    async def test_interaction_simple(self, prompt: str) -> str:
        """Simple test function to be wrapped with interaction."""
        # Simulate some processing
        await asyncio.sleep(0.1)
        return f"Processed: {prompt}"
    
    async def test_llm_call(self, prompt: str, temperature: float = 0.7) -> Dict[str, Any]:
        """Simulate an LLM call."""
        await asyncio.sleep(0.1)
        return {
            "model": "gpt-4",
            "prompt": prompt,
            "temperature": temperature,
            "response": f"This is a test response to: {prompt}",
            "tokens": len(prompt.split()),
        }
    
    async def test_function_with_error(self, value: int) -> int:
        """Test function that raises an error."""
        if value < 0:
            raise ValueError("Value must be non-negative")
        return value * 2
    
    async def send_test_traces(self) -> List[str]:
        """Send test traces using Gentrace SDK interaction() function."""
        print("📤 Sending test OpenTelemetry traces using Gentrace SDK...")
        
        # Get the current tracer for extracting trace IDs
        tracer = trace.get_tracer(__name__)
        
        # Test 1: Simple interaction
        @gentrace.interaction(
            pipeline_id=self.config.pipeline_id,
            name="test-interaction",
            attributes={
                "test.type": "simple",
                "test.framework": "gentrace-sdk"
            }
        )
        async def traced_simple_interaction(prompt: str) -> str:
            return await self.test_interaction_simple(prompt)
        
        # Execute and capture trace ID
        with tracer.start_as_current_span("capture-trace-1") as span:
            _ = await traced_simple_interaction("Hello from Gentrace SDK test!")
            trace_id = format(span.get_span_context().trace_id, '032x')
            self.trace_ids.append(trace_id)
            print(f"  ✅ Sent simple interaction trace: {trace_id[:8]}...")
        
        # Test 2: LLM call simulation
        @gentrace.interaction(
            pipeline_id=self.config.pipeline_id,
            name="test-llm-call",
            attributes={
                "test.type": "llm",
                "llm.provider": "openai",
                "llm.model": "gpt-4",
                "test.framework": "gentrace-sdk"
            }
        )
        async def traced_llm_call(prompt: str, temperature: float = 0.7) -> Dict[str, Any]:
            return await self.test_llm_call(prompt, temperature)
        
        # Execute and capture trace ID
        with tracer.start_as_current_span("capture-trace-2") as span:
            _ = await traced_llm_call("Generate a haiku about testing", 0.5)
            trace_id = format(span.get_span_context().trace_id, '032x')
            self.trace_ids.append(trace_id)
            print(f"  ✅ Sent LLM call trace: {trace_id[:8]}...")
        
        # Test 3: Function with error
        @gentrace.interaction(
            pipeline_id=self.config.pipeline_id,
            name="test-exception",
            attributes={
                "test.type": "error",
                "test.framework": "gentrace-sdk"
            }
        )
        async def traced_error_function(value: int) -> int:
            return await self.test_function_with_error(value)
        
        # Execute with error and capture trace ID
        with tracer.start_as_current_span("capture-trace-3") as span:
            try:
                await traced_error_function(-5)
            except ValueError:
                # Error is automatically recorded by interaction()
                pass
            trace_id = format(span.get_span_context().trace_id, '032x')
            self.trace_ids.append(trace_id)
            print(f"  ✅ Sent error trace: {trace_id[:8]}...")
        
        # Force flush to ensure traces are sent
        trace_provider = trace.get_tracer_provider()
        if hasattr(trace_provider, 'force_flush'):
            trace_provider.force_flush(timeout_millis=5000)
        
        print(f"✅ Sent {len(self.trace_ids)} test traces using Gentrace SDK")
        return self.trace_ids
    
    def connect_postgres(self) -> psycopg2.extensions.connection:
        """Connect to Postgres database."""
        try:
            conn = psycopg2.connect(
                host=self.config.postgres_host,
                port=self.config.postgres_port,
                database=self.config.postgres_db,
                user=self.config.postgres_user,
                password=self.config.postgres_password
            )
            return conn
        except Exception as e:
            print(f"❌ Failed to connect to Postgres: {e}")
            raise
    
    def connect_clickhouse(self) -> clickhouse_driver.Client:
        """Connect to ClickHouse database."""
        try:
            # Build connection parameters
            connect_params = {
                'host': self.config.clickhouse_host,
                'port': self.config.clickhouse_port,
                'database': self.config.clickhouse_db,
            }
            
            # Only add authentication if password is provided
            if self.config.clickhouse_password:
                connect_params['user'] = self.config.clickhouse_user
                connect_params['password'] = self.config.clickhouse_password
            
            client = clickhouse_driver.Client(**connect_params)
            return client
        except Exception as e:
            print(f"❌ Failed to connect to ClickHouse: {e}")
            raise
    
    def validate_postgres_ingestion(self, trace_ids: List[str], max_wait: int = 30) -> bool:
        """Validate that traces were ingested into Postgres GTSpan table."""
        print("🔍 Validating Postgres ingestion...")
        
        conn = self.connect_postgres()
        cursor = conn.cursor()
        
        start_time = time.time()
        found_traces = set()
        found_spans = []
        
        while time.time() - start_time < max_wait:
            try:
                # Query for GTSpan records
                cursor.execute("""
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
                    WHERE "pipelineId" = %s
                    ORDER BY "createdAt" DESC
                    LIMIT 50
                """, (self.config.pipeline_id,))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    span_id, trace_id, name, span_type, start_time, end_time, attrs, otel_span, pipeline_id = row
                    
                    # Check if this span has test attributes
                    if attrs and attrs.get("test", {}).get("framework") == "gentrace-sdk":
                        found_spans.append(name)
                        found_traces.add(trace_id)
                        print(f"  ✅ Found span: {name} (type: {span_type}, trace: {trace_id[:8]}...)")
                        
                        # Validate required fields
                        if not start_time or not end_time:
                            print("    ⚠️  Missing timestamps")
                        if not attrs:
                            print("    ⚠️  Missing attributes")
                        if pipeline_id != self.config.pipeline_id:
                            print(f"    ⚠️  Pipeline ID mismatch: {pipeline_id}")
                
                # Check if we found all expected spans
                expected_spans = {"test-interaction", "test-llm-call", "test-exception"}
                if all(span in " ".join(found_spans) for span in expected_spans):
                    break
                    
                time.sleep(1)
                
            except Exception as e:
                print(f"❌ Error querying Postgres: {e}")
                break
        
        cursor.close()
        conn.close()
        
        success = len(found_spans) >= 3
        if success:
            print(f"✅ Postgres validation successful: {len(found_spans)} spans found")
        else:
            print(f"❌ Postgres validation failed: {len(found_spans)} spans found")
        
        return success
    
    def validate_clickhouse_replication(self, trace_ids: List[str], max_wait: int = 120) -> bool:
        """Validate that data was replicated to ClickHouse span table."""
        print("🔍 Validating ClickHouse replication...")
        print("   Note: ClickHouse replication is eventually consistent, allowing extra time...")
        
        start_time = time.time()
        found_spans = 0
        
        # Add initial settling time for eventual consistency
        print("   ⏳ Waiting 2 seconds for ClickHouse replication to settle...")
        time.sleep(2)
        
        while time.time() - start_time < max_wait:
            try:
                # Use HTTP interface directly instead of clickhouse-driver
                query = f"""
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
                    FROM span 
                    WHERE pipelineId = '{self.config.pipeline_id}'
                    ORDER BY createdAt DESC
                    LIMIT 50
                    FORMAT JSON
                """
                
                # Make HTTP request to ClickHouse
                response = requests.get(
                    f"http://{self.config.clickhouse_host}:{self.config.clickhouse_port}/",
                    params={'query': query},
                    auth=(self.config.clickhouse_user, self.config.clickhouse_password) if self.config.clickhouse_password else None
                )
                
                if response.status_code != 200:
                    print(f"❌ ClickHouse query failed with status {response.status_code}: {response.text}")
                    break
                
                result_data = response.json()
                rows = result_data.get('data', [])
                
                found_spans = 0
                for row in rows:
                    span_id = row['id']
                    name = row['name']
                    function_args = row['functionArgs']
                    function_output = row['functionOutput']
                    attrs_map = row['attributesMap']
                    
                    # Parse attributesMap if it's a JSON string
                    attributes = {}
                    if attrs_map:
                        try:
                            attributes = json.loads(attrs_map)
                        except Exception:
                            pass
                    
                    # Check if this span is from our test
                    if attributes.get("test", {}).get("framework") == "gentrace-sdk":
                        found_spans += 1
                        print(f"  ✅ Found ClickHouse span: {name} (id: {span_id[:8]}...)")
                        
                        # Validate data structure
                        if function_args:
                            try:
                                json.loads(function_args)
                                print("    ✅ Valid functionArgs JSON")
                            except Exception:
                                print("    ⚠️  Invalid functionArgs JSON")
                        
                        if function_output:
                            try:
                                json.loads(function_output)
                                print("    ✅ Valid functionOutput JSON")
                            except Exception:
                                print("    ⚠️  Invalid functionOutput JSON")
                
                if found_spans >= 3:
                    break
                    
                time.sleep(2)
                
            except Exception as e:
                print(f"❌ Error querying ClickHouse: {e}")
                break
        
        success = found_spans >= 3
        if success:
            print(f"✅ ClickHouse validation successful: {found_spans} spans found")
        else:
            print(f"❌ ClickHouse validation failed: {found_spans} spans found")
        
        return success
    
    async def run_full_test(self) -> bool:
        """Run the complete ingestion pipeline test."""
        print("🚀 Starting Gentrace ingestion pipeline test (using Gentrace SDK)")
        print(f"   Base URL: {self.config.gentrace_base_url}")
        print(f"   Postgres: {self.config.postgres_host}:{self.config.postgres_port}")
        print(f"   ClickHouse: {self.config.clickhouse_host}:{self.config.clickhouse_port}")
        print(f"   Pipeline ID: {self.config.pipeline_id}")
        print()
        
        # Step 1: Send test traces
        try:
            trace_ids = await self.send_test_traces()
        except Exception as e:
            print(f"❌ Failed to send test traces: {e}")
            return False
        
        # Step 2: Validate Postgres ingestion
        postgres_success = self.validate_postgres_ingestion(trace_ids)
        
        # Step 3: Validate ClickHouse replication
        clickhouse_success = self.validate_clickhouse_replication(trace_ids)
        
        # Summary
        print("\n📊 Test Results Summary:")
        print("   Trace Sending: ✅")
        print(f"   Postgres Ingestion: {'✅' if postgres_success else '❌'}")
        print(f"   ClickHouse Replication: {'✅' if clickhouse_success else '❌'}")
        
        overall_success = postgres_success and clickhouse_success
        
        if overall_success:
            print("\n🎉 All tests passed! Ingestion pipeline is working correctly.")
        else:
            print("\n💥 Some tests failed. Check the logs above for details.")
        
        return overall_success


async def async_main():
    """Async main entry point."""
    # Load configuration
    config = TestConfig.from_env()
    
    # Run the test
    tester = IngestionTester(config)
    success = await tester.run_full_test()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


def main():
    """Main entry point."""
    print("Gentrace Self-Hosted Ingestion Pipeline Test")
    print("=" * 50)
    
    # Run async main
    asyncio.run(async_main())


if __name__ == "__main__":
    main() 
