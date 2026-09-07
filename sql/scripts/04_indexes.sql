/*
===============================================================================
FinSight - Analytics Indexes
===============================================================================
Purpose:
    - Creates indexes for frequently used foreign keys and filtering columns
      in the analytics fact table.
    - Improves performance of joins, filtering, and analytical queries.
    - Indexes are created only if they do not already exist.
===============================================================================
*/

-- =============================================================================
-- User Index
-- =============================================================================
-- Supports joins and filtering by user.

create index if not exists idx_fact_transactions_user_key
on analytics.fact_transactions(user_key);


-- =============================================================================
-- Card Index
-- =============================================================================
-- Supports joins and filtering by card.

create index if not exists idx_fact_transactions_card_key
on analytics.fact_transactions(card_key);


-- =============================================================================
-- MCC Index
-- =============================================================================
-- Supports joins with the merchant category dimension
-- and transaction analysis by merchant category.

create index if not exists idx_fact_transactions_mcc_key
on analytics.fact_transactions(mcc_key);


-- =============================================================================
-- Date Index
-- =============================================================================
-- Supports joins with the date dimension
-- and filtering transactions by date.

create index if not exists idx_fact_transactions_date_key
on analytics.fact_transactions(date_key);


-- =============================================================================
-- Merchant Index
-- =============================================================================
-- Supports filtering and aggregation by merchant.
-- Performance impact was evaluated separately using explain analyze.

create index if not exists idx_fact_transactions_merchant_id
on analytics.fact_transactions(merchant_id);

-- =============================================================================
-- Customer Lifecycle Index
-- =============================================================================
-- Supports customer-level chronological analysis by user and transaction time.
-- Used for lifecycle, repeat activity, and retention analysis.

create index if not exists idx_fact_transactions_user_timestamp
on analytics.fact_transactions (user_key, transaction_timestamp);

-- =============================================================================
-- Card Transaction History Index
-- =============================================================================
-- Supports card-level chronological analysis by card and transaction time.
-- Used for fraud detection feature engineering and historical card behavior.

create index if not exists idx_fact_transactions_card_timestamp
on analytics.fact_transactions (card_key, transaction_timestamp);