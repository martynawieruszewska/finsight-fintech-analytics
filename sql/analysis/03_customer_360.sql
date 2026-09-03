/*
===============================================================================
FinSight - Customer 360 Analysis
===============================================================================
Purpose:
    - Builds a customer-level analytical view.
    - Summarizes transaction activity, spending, recency, card ownership,
      and fraud activity for each user.
    - Provides the foundation for customer segmentation and RFM analysis.
===============================================================================
*/

-- =============================================================================
-- Customer 360
-- =============================================================================
-- one row represents one customer and summarizes their overall activity

with dataset_end as (
	select
		max(transaction_timestamp) as dataset_end_date
	from analytics.fact_transactions
),

user_months as (
	select distinct
		user_key,
		date_trunc('month', transaction_timestamp) as month
	from analytics.fact_transactions
),

active_months as (
	select
		user_key,
		count(*) as active_months
	from user_months
	group by user_key
),

customer_metrics as (
	select
		user_key,
		count(*) as transaction_count,
		sum(amount) filter (where amount > 0) as gross_total_spend,
		round(avg(amount) filter (where amount > 0), 2) as avg_ticket,
		max(transaction_timestamp) as last_transaction_date,
		count(is_fraud) filter (where is_fraud is true) as fraud_count
	from analytics.fact_transactions
	group by user_key
),

customer_cards as (
	select
		user_key,
		count(card_id) as card_count
	from analytics.dim_cards
	group by user_key
)

select
	c.user_key,
	c.transaction_count,
	c.gross_total_spend,
	c.avg_ticket,
	a.active_months,
	c.last_transaction_date,
	d.dataset_end_date,
	d.dataset_end_date::date - c.last_transaction_date::date as recency_days,
	cc.card_count,
	c.fraud_count
from customer_metrics c
left join active_months a
	on c.user_key = a.user_key
cross join dataset_end d
left join customer_cards cc
	on c.user_key = cc.user_key
order by user_key;

