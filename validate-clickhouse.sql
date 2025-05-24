-- ClickHouse validation queries for Gentrace ingestion pipeline
-- Run these queries to manually validate data replication

-- 1. Check recent span records
SELECT 
    id,
    createdAt,
    name,
    startTime,
    endTime,
    parentId,
    runId,
    length(inputs) as inputs_size,
    length(outputs) as outputs_size,
    length(metadata) as metadata_size
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
ORDER BY createdAt DESC
LIMIT 20;

-- 2. Count spans by time buckets
SELECT 
    toStartOfMinute(createdAt) as minute,
    COUNT(*) as span_count
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
GROUP BY minute
ORDER BY minute DESC
LIMIT 10;

-- 3. Check data sizes and compression
SELECT 
    'Total spans' as metric,
    COUNT(*) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR

UNION ALL

SELECT 
    'Avg inputs size (bytes)' as metric,
    ROUND(AVG(length(inputs))) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND inputs != ''

UNION ALL

SELECT 
    'Avg outputs size (bytes)' as metric,
    ROUND(AVG(length(outputs))) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND outputs != ''

UNION ALL

SELECT 
    'Avg metadata size (bytes)' as metric,
    ROUND(AVG(length(metadata))) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND metadata != '';

-- 4. Check for valid JSON in inputs/outputs
SELECT 
    id,
    name,
    CASE 
        WHEN isValidJSON(inputs) THEN 'Valid'
        ELSE 'Invalid'
    END as inputs_json_status,
    CASE 
        WHEN isValidJSON(outputs) THEN 'Valid'
        ELSE 'Invalid'
    END as outputs_json_status,
    CASE 
        WHEN isValidJSON(metadata) THEN 'Valid'
        ELSE 'Invalid'
    END as metadata_json_status
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND (inputs != '' OR outputs != '' OR metadata != '')
ORDER BY createdAt DESC
LIMIT 10;

-- 5. Check for spans with specific patterns (test data)
SELECT 
    id,
    name,
    createdAt,
    startTime,
    endTime,
    runId
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND (
    name LIKE '%test%' 
    OR name LIKE '%Test%'
    OR inputs LIKE '%test%'
    OR outputs LIKE '%test%'
  )
ORDER BY createdAt DESC
LIMIT 10;

-- 6. Performance metrics
SELECT 
    'Min span duration (ms)' as metric,
    MIN(toUnixTimestamp(endTime) - toUnixTimestamp(startTime)) * 1000 as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND endTime IS NOT NULL 
  AND startTime IS NOT NULL

UNION ALL

SELECT 
    'Max span duration (ms)' as metric,
    MAX(toUnixTimestamp(endTime) - toUnixTimestamp(startTime)) * 1000 as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND endTime IS NOT NULL 
  AND startTime IS NOT NULL

UNION ALL

SELECT 
    'Avg span duration (ms)' as metric,
    ROUND(AVG(toUnixTimestamp(endTime) - toUnixTimestamp(startTime)) * 1000) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR
  AND endTime IS NOT NULL 
  AND startTime IS NOT NULL;

-- 7. Data freshness check
SELECT 
    'Latest span age (minutes)' as metric,
    ROUND(dateDiff('minute', MAX(createdAt), now())) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 HOUR

UNION ALL

SELECT 
    'Spans in last 5 minutes' as metric,
    COUNT(*) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 5 MINUTE

UNION ALL

SELECT 
    'Spans in last 1 minute' as metric,
    COUNT(*) as value
FROM span 
WHERE createdAt >= now() - INTERVAL 1 MINUTE;

