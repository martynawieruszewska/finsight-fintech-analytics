/*
===============================================================================
FinSight - Analytics Data Tests
===============================================================================
Purpose:
    - Validates data loaded into the analytics dimensional model.
    - Compares staging and analytics row counts.
    - Detects records lost during dimensional joins.
===============================================================================
*/

-- =============================================================================
-- Row Count Validation
-- =============================================================================

select
    'users' as dataset,
    (select count(*) from staging.users) as staging_rows,
    (select count(*) from analytics.dim_users) as analytics_rows

union all

select
    'cards',
    (select count(*) from staging.cards),
    (select count(*) from analytics.dim_cards)

union all

select
    'mcc',
    (select count(*) from staging.mcc_codes),
    (select count(*) from analytics.dim_mcc)

union all

select
    'transactions',
    (select count(*) from staging.transactions),
    (select count(*) from analytics.fact_transactions);

-- =============================================================================
-- Fact Table Key Validation
-- =============================================================================

select
    count(*) filter (where transaction_id is null) as null_transaction_id,
    count(*) filter (where user_key is null) as null_user_key,
    count(*) filter (where card_key is null) as null_card_key,
    count(*) filter (where mcc_key is null) as null_mcc_key,
    count(*) filter (where date_key is null) as null_date_key
from analytics.fact_transactions;

-- =============================================================================
-- Duplicate Key Validation
-- =============================================================================

select
    'dim_users.user_id' as key,
    count(*) - count(distinct user_id) as duplicates
from analytics.dim_users

union all

select
    'dim_cards.card_id',
    count(*) - count(distinct card_id)
from analytics.dim_cards

union all

select
    'dim_mcc.mcc',
    count(*) - count(distinct mcc)
from analytics.dim_mcc

union all

select
    'dim_date.date_key',
    count(*) - count(distinct date_key)
from analytics.dim_date

union all

select
    'fact_transactions.transaction_id',
    count(*) - count(distinct transaction_id)
from analytics.fact_transactions;

-- =============================================================================
-- Fraud Label Validation
-- =============================================================================

select
    (select count(*)
     from staging.fraud_labels
     where is_fraud = true) as staging_fraud_rows,

    (select count(*)
     from analytics.fact_transactions
     where is_fraud = true) as analytics_fraud_rows;
    
  -- =============================================================================
-- Orphan Foreign Key Validation
-- =============================================================================

select
    count(*) as orphan_user_keys
from analytics.fact_transactions f
left join analytics.dim_users u
    on f.user_key = u.user_key
where u.user_key is null;

select
    count(*) as orphan_card_keys
from analytics.fact_transactions f
left join analytics.dim_cards c
    on f.card_key = c.card_key
where c.card_key is null;

select
    count(*) as orphan_mcc_keys
from analytics.fact_transactions f
left join analytics.dim_mcc m
    on f.mcc_key = m.mcc_key
where m.mcc_key is null;

select
    count(*) as orphan_date_keys
from analytics.fact_transactions f
left join analytics.dim_date d
    on f.date_key = d.date_key
where d.date_key is null;