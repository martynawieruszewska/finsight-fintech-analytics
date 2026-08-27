/*
===============================================================================
FinSight - Schema Tests
===============================================================================
Purpose:
    - Validates the structure of the FinSight PostgreSQL database.
    - Confirms that required schemas and staging tables exist.
    - Verifies column names and data types after schema creation.

Note:
    - These queries do not modify any data.
    - Run after `02_schema.sql`.
===============================================================================
*/


-- =============================================================================
-- Test 1: Check Required Schemas
-- =============================================================================

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('staging', 'analytics')
ORDER BY schema_name;


-- =============================================================================
-- Test 2: Check Staging Tables
-- =============================================================================

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
ORDER BY table_name;


-- Expected staging tables:
-- cards
-- fraud_labels
-- mcc_codes
-- transactions
-- users


-- =============================================================================
-- Test 3: Check Users Schema
-- =============================================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'users'
ORDER BY ordinal_position;


-- =============================================================================
-- Test 4: Check Cards Schema
-- =============================================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'cards'
ORDER BY ordinal_position;


-- =============================================================================
-- Test 5: Check Transactions Schema
-- =============================================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'transactions'
ORDER BY ordinal_position;


-- =============================================================================
-- Test 6: Check MCC Codes Schema
-- =============================================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'mcc_codes'
ORDER BY ordinal_position;


-- =============================================================================
-- Test 7: Check Fraud Labels Schema
-- =============================================================================

SELECT
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'fraud_labels'
ORDER BY ordinal_position;