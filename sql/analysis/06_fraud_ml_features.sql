/*
===============================================================================
FinSight - Fraud Detection ML Feature Engineering
===============================================================================
Purpose:
    - Prepares transaction-level features for fraud detection modeling.
    - Defines the ML observation unit as a single transaction.
    - Uses only information available at or before transaction time.
    - Excludes transactions without a known fraud label from model training.
===============================================================================
*/

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
	round(
		count(is_fraud)::numeric / count(*) * 100,
		2
	) as label_coverage_pct,
	round(
		count(*) filter (where is_fraud = true)::numeric
		/ count(is_fraud) * 100,
		4
	) as fraud_rate_pct
from analytics.fact_transactions;

with transaction_features as (
	select
		transaction_key,
		user_key,
		card_key,
		amount,
		mcc_key,
		use_chip,
		merchant_id,
		transaction_timestamp,
		extract(hour from transaction_timestamp) as transaction_hour,
		extract(dow from transaction_timestamp) as day_of_week,
		case
			when extract(dow from transaction_timestamp) in (0, 6) then 1
			else 0
		end as is_weekend,
		is_fraud
	from analytics.fact_transactions
)

select 
	*,
	count(*) over (partition by user_key order by transaction_timestamp rows between unbounded preceding and 1 preceding) as user_previous_transaction_count,
	round(avg(amount) over (partition by user_key order by transaction_timestamp rows between unbounded preceding and 1 preceding), 2) as user_previous_avg_amount
from transaction_features
where user_key = 1
order by transaction_timestamp
limit 10;
 