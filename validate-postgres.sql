-- Postgres validation queries for Gentrace ingestion pipeline
-- Run these queries to manually validate data ingestion

-- 1. Check recent GTSpan records
SELECT 
    id,
    "createdAt",
    "traceId",
    name,
    type,
    "startTime",
    "endTime",
    "pipelineId",
    "organizationId",
    CASE 
        WHEN "sourceOtelSpan" = 'null' THEN 'Missing'
        ELSE 'Present'
    END as otel_span_status
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
ORDER BY "createdAt" DESC
LIMIT 20;

-- 2. Count spans by type
SELECT 
    type,
    COUNT(*) as count,
    MIN("createdAt") as earliest,
    MAX("createdAt") as latest
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
GROUP BY type
ORDER BY count DESC;

-- 3. Check for spans with specific attributes
SELECT 
    id,
    name,
    type,
    "attributesMap"->>'gentrace.pipeline_id' as pipeline_id,
    "attributesMap"->>'gentrace.sample' as sample_flag,
    "attributesMap"->>'function.name' as function_name
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
  AND "attributesMap"->>'gentrace.sample' = 'true'
ORDER BY "createdAt" DESC
LIMIT 10;

-- 4. Check LLM spans specifically
SELECT 
    id,
    name,
    "llmProvider",
    "llmModelName",
    "llmMessages",
    "llmChoices"
FROM "GTSpan" 
WHERE type = 'llm'
  AND "createdAt" >= NOW() - INTERVAL '1 hour'
ORDER BY "createdAt" DESC
LIMIT 5;

-- 5. Check exception spans
SELECT 
    id,
    name,
    "statusType",
    "errorType",
    "errorMessage",
    "errorStacktrace"
FROM "GTSpan" 
WHERE "statusType" != 'UNSET'
  AND "createdAt" >= NOW() - INTERVAL '1 hour'
ORDER BY "createdAt" DESC
LIMIT 5;

-- 6. Check buffered spans (if any)
SELECT 
    id,
    "traceId",
    "organizationId",
    "createdAt"
FROM "BufferedSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
ORDER BY "createdAt" DESC
LIMIT 10;

-- 7. Validate data integrity
SELECT 
    'Total GTSpans' as metric,
    COUNT(*) as value
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
    'Spans with valid timestamps' as metric,
    COUNT(*) as value
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
  AND "startTime" IS NOT NULL 
  AND "endTime" IS NOT NULL

UNION ALL

SELECT 
    'Spans with OTEL source data' as metric,
    COUNT(*) as value
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
  AND "sourceOtelSpan" != 'null'

UNION ALL

SELECT 
    'Spans with pipeline ID' as metric,
    COUNT(*) as value
FROM "GTSpan" 
WHERE "createdAt" >= NOW() - INTERVAL '1 hour'
  AND "pipelineId" IS NOT NULL;

