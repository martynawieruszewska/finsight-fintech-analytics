/*
===============================================================================
FinSight - Index Performance Tests
===============================================================================
Purpose:
    - Compares query performance before and after adding an index.
    - Shows how PostgreSQL changes the execution plan depending on the query.
    - Demonstrates the difference between sequential scans, bitmap scans,
      and index-only scans.
===============================================================================
*/

-- =============================================================================
-- Baseline Query
-- =============================================================================
-- Before creating an index on merchant_id, PostgreSQL used:
-- parallel seq scan
--
-- observed execution time:
-- ~1853.55 ms

explain analyze
select *
from analytics.fact_transactions
where merchant_id = 59935;


-- =============================================================================
-- Query After Creating Index
-- =============================================================================
-- index:
-- idx_fact_transactions_merchant_id
--
-- PostgreSQL changed the execution plan to:
-- parallel bitmap heap scan
--
-- observed execution time:
-- ~5271.70 ms
--
-- the index was used, but the query became slower because select *
-- requires PostgreSQL to retrieve full rows from the fact table.
-- around 610,000 transactions match this merchant_id.

explain analyze
select *
from analytics.fact_transactions
where merchant_id = 59935;


-- =============================================================================
-- Index Only Scan Test
-- =============================================================================
-- count(*) does not require all columns from fact_transactions.
-- PostgreSQL can satisfy the query directly from the merchant_id index.
--
-- execution plan:
-- parallel index only scan
--
-- observed execution time:
-- ~53.58 ms
--
-- heap fetches: 0
--
-- this means PostgreSQL did not need to fetch rows from the main table.

explain analyze
select count(*)
from analytics.fact_transactions
where merchant_id = 59935;