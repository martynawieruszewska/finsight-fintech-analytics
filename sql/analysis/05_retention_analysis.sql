/*
===============================================================================
FinSight - Customer Lifecycle & Retention Analysis
===============================================================================
Purpose:
    - Analyzes customer activity over time.
    - Identifies customer activation and repeat transaction behavior.
    - Builds customer cohorts based on first transaction date.
    - Measures customer retention across cohort lifetime.
===============================================================================
*/

-- =============================================================================
-- Customer Activation
-- =============================================================================
-- identifies each customer's first observed transaction
-- and groups customers by their first observed transaction month

with customer_activation as (
select 
	user_key,
	min(transaction_timestamp) as first_transaction_date,
	date_trunc('month', min(transaction_timestamp)) as first_transaction_month
from analytics.fact_transactions 
group by user_key
)
select
	first_transaction_month,
	count(user_key) as nr_of_cust
from customer_activation
group by first_transaction_month;

-- =============================================================================
-- Repeat Activity
-- =============================================================================
-- identifies the first and second observed transaction for each customer
-- and measures the time between them

with ranked_transactions as (
	select
		user_key,
		transaction_timestamp,
		row_number() over (
			partition by user_key
			order by transaction_timestamp
		) as flag
	from analytics.fact_transactions
),
first_two_transactions as (
	select
		*
	from ranked_transactions
	where flag between 1 and 2
),
customer_repeat_activity as (
select
	user_key,
	max(case when flag = 1 then transaction_timestamp end) as first_transaction,
	max(case when flag = 2 then transaction_timestamp end) as second_transaction
from first_two_transactions
group by user_key
order by user_key
),
repeat_activity_gaps as (
select 
	user_key,
	first_transaction,
	second_transaction,
	second_transaction - first_transaction as gap
from customer_repeat_activity
)

select 
	min(gap) as min_gap,
	avg(gap) as avg_gap,
	percentile_cont(0.5) within group (order by gap) AS median_gap,
	max(gap) as max_gap,
	round(count(second_transaction)::numeric/count(user_key)*100, 2) as repeat_rate
from repeat_activity_gaps;
