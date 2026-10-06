/*
===============================================================================
FinSight - Fraud Target Analysis
===============================================================================
Purpose:
    - Examines fraud label availability and class imbalance before
      model development.
    - The ML feature view itself is created in
      sql/scripts/05_fraud_ml_features.sql.
===============================================================================
*/

-- =============================================================================
-- Fact Table Structure
-- =============================================================================

select *
from analytics.fact_transactions
limit 10;

select
	column_name,
	data_type
from information_schema.columns
where table_schema = 'analytics'
	and table_name = 'fact_transactions'
order by ordinal_position;

-- =============================================================================
-- Fraud Target EDA
-- =============================================================================
-- examines target availability and class imbalance before model development

select
	is_fraud,
	count(*) as transaction_count
from analytics.fact_transactions
group by is_fraud;

select
	count(*) as total_transactions,
	count(is_fraud) as labeled_transactions,
	count(*) filter (where is_fraud = true) as fraud_transactions,
	round(count(is_fraud)::numeric / count(*) * 100, 2) as label_coverage_pct,
	round(count(*) filter (where is_fraud = true)::numeric / count(is_fraud) * 100, 4) as fraud_rate_pct
from analytics.fact_transactions;

-- =============================================================================
-- Feature View Validation
-- =============================================================================

select count(*)
from analytics.fraud_ml_features;

select *
from analytics.fraud_ml_features
limit 10;

-- =============================================================================
-- Label Coverage and Fraud Rate Over Time
-- =============================================================================

select
	extract(year from transaction_timestamp) as year,
	count(*) as transaction_count,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	round(count(is_fraud)::numeric / count(*) *  100, 2) as label_coverage_pct,
	count(*) filter (where is_fraud is true) as fraud_trans,
	round((count(*) filter (where is_fraud is true))::numeric / count(is_fraud) *  100, 2) as fraud_rate_pct
from analytics.fact_transactions
group by extract(year from transaction_timestamp)
order by extract(year from transaction_timestamp);