#!/usr/bin/env python3
"""
Comprehensive test for Gentrace self-hosted container setup.

This script tests the full data ingestion pipeline:
1. Sends OpenTelemetry traces to the OTEL endpoint
2. Validates data ingestion in Postgres (GTSpan table)
3. Validates data replication to ClickHouse (span table)

Requirements:
- Docker compose environment running
- Python packages: requests, psycopg2-binary, clickhouse-driver, opentelemetry-api, opentelemetry-sdk, opentelemetry-exporter-otlp-proto-http
"""

import os
import sys
import time
import json
import uuid
import requests
import psycopg2
import clickhouse_driver
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

# OpenTelemetry imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter


@dataclass
class TestConfig:
    """Configuration for the ingestion test."""
    gentrace_base_url: str = "http://localhost:3000"
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "gentrace"
    postgres_user: str = "postgres"
    postgres_password: str = "password"
    clickhouse_host: str = "localhost"
    clickhouse_port: int = 8123
    clickhouse_db: str = "default"
    clickhouse_user: str = "default"
    clickhouse_password: str = ""
    api_key: str = "gt-test-key"  # Default test API key
    organization_id: str = "test-org-id"
    pipeline_id: str = "test-pipeline-id"
    
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
        self.test_trace_id = str(uuid.uuid4())
        self.test_span_id = str(uuid.uuid4())
        self.test_start_time = datetime.now(timezone.utc)
        
    def setup_otel_tracer(self) -> trace.Tracer:
        """Set up OpenTelemetry tracer for sending test data."""
        resource = Resource(attributes={
            "service.name": "gentrace-ingestion-test",
            "service.version": "1.0.0"
        })
        
        tracer_provider = TracerProvider(resource=resource)
        
        # Configure OTLP exporter
        otlp_headers = {
            "Authorization": f"Bearer {self.config.api_key}",
            "Content-Type": "application/x-protobuf"
        }
        
        span_exporter = OTLPSpanExporter(
            endpoint=f"{self.config.gentrace_base_url}/api/otel/v1/traces",
            headers=otlp_headers
        )
        
        span_processor = SimpleSpanProcessor(span_exporter)
        tracer_provider.add_span_processor(span_processor)
        
        trace.set_tracer_provider(tracer_provider)
        return trace.get_tracer(__name__)
    
    def send_test_traces(self) -> List[str]:
        """Send test OpenTelemetry traces and return trace IDs."""
        tracer = self.setup_otel_tracer()
        trace_ids = []
        
        print("📤 Sending test OpenTelemetry traces...")
        
        # Test trace 1: Simple interaction
        with tracer.start_as_current_span("test-interaction") as span:
            span.set_attribute("gentrace.pipeline_id", self.config.pipeline_id)
            span.set_attribute("gentrace.sample", "true")
            span.set_attribute("gentrace.type", "interaction")
            span.set_attribute("function.name", "test_function")
            span.set_attribute("function.args", json.dumps(["arg1", "arg2"]))
            span.set_attribute("function.output", json.dumps({"result": "test output"}))
            
            trace_id = format(span.get_span_context().trace_id, '032x')
            trace_ids.append(trace_id)
            
            time.sleep(0.1)  # Simulate some work
        
        # Test trace 2: LLM call
        with tracer.start_as_current_span("test-llm-call") as span:
            span.set_attribute("gentrace.pipeline_id", self.config.pipeline_id)
            span.set_attribute("gentrace.sample", "true")
            span.set_attribute("gentrace.type", "llm")
            span.set_attribute("llm.provider", "openai")
            span.set_attribute("llm.model", "gpt-4")
            span.set_attribute("llm.messages", json.dumps([
                {"role": "user", "content": "Hello, world!"}
            ]))
            span.set_attribute("llm.choices", json.dumps([
                {"message": {"role": "assistant", "content": "Hello! How can I help you?"}}
            ]))
            
            trace_id = format(span.get_span_context().trace_id, '032x')
            trace_ids.append(trace_id)
            
            time.sleep(0.1)
        
        # Test trace 3: Exception/error
        with tracer.start_as_current_span("test-exception") as span:
            span.set_attribute("gentrace.pipeline_id", self.config.pipeline_id)
            span.set_attribute("gentrace.sample", "true")
            span.set_attribute("gentrace.type", "function")
            
            # Simulate an exception
            span.record_exception(Exception("Test exception for ingestion testing"))
            span.set_status(trace.Status(trace.StatusCode.ERROR, "Test error"))
            
            trace_id = format(span.get_span_context().trace_id, '032x')
            trace_ids.append(trace_id)
        
        # Force flush to ensure traces are sent
        trace.get_tracer_provider().force_flush(timeout_millis=5000)
        
        print(f"✅ Sent {len(trace_ids)} test traces")
        return trace_ids
    
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
            client = clickhouse_driver.Client(
                host=self.config.clickhouse_host,
                port=self.config.clickhouse_port,
                database=self.config.clickhouse_db,
                user=self.config.clickhouse_user,
                password=self.config.clickhouse_password
            )
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
                    WHERE "organizationId" = %s
                    ORDER BY "createdAt" DESC
                    LIMIT 50
                """, (self.config.organization_id,))
                
                rows = cursor.fetchall()
                
                for row in rows:
                    span_id, trace_id, name, span_type, start_time, end_time, attrs, otel_span, pipeline_id = row
                    
                    # Check if this is one of our test traces
                    if any(tid in trace_id for tid in trace_ids):
                        found_traces.add(trace_id)
                        print(f"  ✅ Found span: {name} (type: {span_type}, trace: {trace_id[:8]}...)")
                        
                        # Validate required fields
                        if not start_time or not end_time:
                            print(f"    ⚠️  Missing timestamps")
                        if not attrs:
                            print(f"    ⚠️  Missing attributes")
                        if otel_span == "null":
                            print(f"    ⚠️  Missing sourceOtelSpan")
                        if pipeline_id != self.config.pipeline_id:
                            print(f"    ⚠️  Pipeline ID mismatch: {pipeline_id}")
                
                if len(found_traces) >= len(trace_ids):
                    break
                    
                time.sleep(1)
                
            except Exception as e:
                print(f"❌ Error querying Postgres: {e}")
                break
        
        cursor.close()
        conn.close()
        
        success = len(found_traces) >= len(trace_ids)
        if success:
            print(f"✅ Postgres validation successful: {len(found_traces)}/{len(trace_ids)} traces found")
        else:
            print(f"❌ Postgres validation failed: {len(found_traces)}/{len(trace_ids)} traces found")
        
        return success
    
    def validate_clickhouse_replication(self, trace_ids: List[str], max_wait: int = 120) -> bool:
        """Validate that data was replicated to ClickHouse span table."""
        print("🔍 Validating ClickHouse replication...")
        print("   Note: ClickHouse replication is eventually consistent, allowing extra time...")
        
        client = self.connect_clickhouse()
        
        start_time = time.time()
        found_spans = 0
        
        # Add initial settling time for eventual consistency
        print("   ⏳ Waiting 30 seconds for ClickHouse replication to settle...")
        time.sleep(30)
        
        while time.time() - start_time < max_wait:
            try:
                # Query ClickHouse span table
                result = client.execute("""
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
                """)
                
                found_spans = 0
                for row in result:
                    span_id, name, inputs, outputs, start_time, end_time, metadata, run_id = row
                    
                    # Check if this span is related to our test
                    if any(tid in str(span_id) for tid in trace_ids) or "test" in name.lower():
                        found_spans += 1
                        print(f"  ✅ Found ClickHouse span: {name} (id: {span_id[:8]}...)")
                        
                        # Validate data structure
                        if inputs:
                            try:
                                json.loads(inputs)
                                print(f"    ✅ Valid inputs JSON")
                            except:
                                print(f"    ⚠️  Invalid inputs JSON")
                        
                        if outputs:
                            try:
                                json.loads(outputs)
                                print(f"    ✅ Valid outputs JSON")
                            except:
                                print(f"    ⚠️  Invalid outputs JSON")
                
                if found_spans > 0:
                    break
                    
                time.sleep(2)
                
            except Exception as e:
                print(f"❌ Error querying ClickHouse: {e}")
                break
        
        success = found_spans > 0
        if success:
            print(f"✅ ClickHouse validation successful: {found_spans} spans found")
        else:
            print(f"❌ ClickHouse validation failed: no spans found")
        
        return success
    
    def test_api_endpoint_health(self) -> bool:
        """Test that the OTEL API endpoint is accessible."""
        print("🏥 Testing API endpoint health...")
        
        try:
            # Test basic connectivity
            response = requests.get(f"{self.config.gentrace_base_url}/api/health", timeout=10)
            if response.status_code == 200:
                print("✅ API endpoint is accessible")
                return True
            else:
                print(f"⚠️  API endpoint returned status {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ API endpoint health check failed: {e}")
            return False
    
    def run_full_test(self) -> bool:
        """Run the complete ingestion pipeline test."""
        print("🚀 Starting Gentrace ingestion pipeline test")
        print(f"   Base URL: {self.config.gentrace_base_url}")
        print(f"   Postgres: {self.config.postgres_host}:{self.config.postgres_port}")
        print(f"   ClickHouse: {self.config.clickhouse_host}:{self.config.clickhouse_port}")
        print()
        
        # Step 1: Test API health
        if not self.test_api_endpoint_health():
            return False
        
        # Step 2: Send test traces
        try:
            trace_ids = self.send_test_traces()
        except Exception as e:
            print(f"❌ Failed to send test traces: {e}")
            return False
        
        # Step 3: Validate Postgres ingestion
        postgres_success = self.validate_postgres_ingestion(trace_ids)
        
        # Step 4: Validate ClickHouse replication
        clickhouse_success = self.validate_clickhouse_replication(trace_ids)
        
        # Summary
        print("\n📊 Test Results Summary:")
        print(f"   API Health: ✅")
        print(f"   Trace Sending: ✅")
        print(f"   Postgres Ingestion: {'✅' if postgres_success else '❌'}")
        print(f"   ClickHouse Replication: {'✅' if clickhouse_success else '❌'}")
        
        overall_success = postgres_success and clickhouse_success
        
        if overall_success:
            print("\n🎉 All tests passed! Ingestion pipeline is working correctly.")
        else:
            print("\n💥 Some tests failed. Check the logs above for details.")
        
        return overall_success


def main():
    """Main entry point."""
    print("Gentrace Self-Hosted Ingestion Pipeline Test")
    print("=" * 50)
    
    # Load configuration
    config = TestConfig.from_env()
    
    # Run the test
    tester = IngestionTester(config)
    success = tester.run_full_test()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
