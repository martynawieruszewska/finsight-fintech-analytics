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

-- =============================================================================
-- Cohort Analysis
-- =============================================================================
-- assigns customers to cohorts based on their first observed transaction month
-- and tracks their transaction activity across subsequent months

drop view if exists analytics.cohort_retention;

create view analytics.cohort_retention as

with cohort_activity as (
select 	
	user_key,
	min(date_trunc('month', transaction_timestamp)) over (partition by user_key) as cohort_month,
	date_trunc('month', transaction_timestamp) as activity_month
from analytics.fact_transactions
), cohort_lifecycle as (

select 
	user_key,
	cohort_month,
	activity_month,
	(

		extract(year from activity_month) - extract(year from cohort_month)
	) * 12
	+
	(
		extract(month from activity_month) - extract(month from cohort_month)
	) as months_since_first_transaction
from cohort_activity
), 

cohort_monthly_activity as (
select
	cohort_month,
	months_since_first_transaction,
	count(distinct user_key) as active_customers
from cohort_lifecycle
group by 
	cohort_month,
	months_since_first_transaction
), 

cohort_with_size as (
	select
		cohort_month,
		months_since_first_transaction,
		active_customers,
		max(active_customers) filter (
			where months_since_first_transaction = 0
		) over (
			partition by cohort_month
		) as cohort_size
	from cohort_monthly_activity
)

select
	cohort_month,
	months_since_first_transaction,
	active_customers,
	cohort_size,
	round(active_customers::numeric / cohort_size * 100, 2) as retention_rate
from cohort_with_size
order by
	cohort_month,
	months_since_first_transaction;

-- =============================================================================
-- Retention by Customer Group
-- =============================================================================
-- compares cohort retention across customer groups based on card ownership


-- Card ownership distribution
-- used to define interpretable customer groups

with customer_card_profile as (
	select
		user_key,
		count(card_id) as number_of_cards
	from analytics.dim_cards
	group by user_key
)

select
	number_of_cards,
	count(user_key) as number_of_customers
from customer_card_profile
group by number_of_cards
order by number_of_cards;


-- Card ownership groups
-- 1 card = single
-- 2–3 cards = multi
-- 4+ cards = high ownership

with customer_card_profile as (
	select
		user_key,
		count(card_id) as number_of_cards,
		case
			when count(card_id) >= 4 then 'high'
			when count(card_id) between 2 and 3 then 'multi'
			else 'single'
		end as card_group
	from analytics.dim_cards
	group by user_key
)

select
	card_group,
	count(*) as number_of_customers
from customer_card_profile
group by card_group
order by number_of_customers desc;

-- =============================================================================
-- Retention by Card Ownership Group
-- =============================================================================
-- compares monthly cohort retention across single-card, multi-card,
-- and high card ownership customer groups

with customer_card_profile as (
	select
		user_key,
		case
			when count(card_id) >= 4 then 'high'
			when count(card_id) between 2 and 3 then 'multi'
			else 'single'
		end as card_group
	from analytics.dim_cards
	group by user_key
),

cohort_activity_by_card_group as (
	select
		t.user_key,
		c.card_group,
		min(date_trunc('month', t.transaction_timestamp)) over (
			partition by t.user_key
		) as cohort_month,
		date_trunc('month', t.transaction_timestamp) as activity_month
	from analytics.fact_transactions t
	left join customer_card_profile c
		on t.user_key = c.user_key
), 

cohort_lifecycle_by_card_group as (
	select 
		user_key,
		card_group,
		cohort_month,
		activity_month,
		(
			extract(year from activity_month) - extract(year from cohort_month)
		) * 12
		+
		(
			extract(month from activity_month) - extract(month from cohort_month)
		) as months_since_first_transaction
	from cohort_activity_by_card_group
),

cohort_monthly_activity_by_card_group as (
	select
		card_group,
		cohort_month,
		months_since_first_transaction,
		count(distinct user_key) as active_customers
	from cohort_lifecycle_by_card_group
	group by
		card_group,
		cohort_month,
		months_since_first_transaction
),

cohort_with_size_by_card_group as (
	select
		card_group,
		cohort_month,
		months_since_first_transaction,
		active_customers,
		max(active_customers) filter (
			where months_since_first_transaction = 0
		) over (
			partition by card_group, cohort_month
		) as cohort_size
	from cohort_monthly_activity_by_card_group
)

select
	card_group,
	months_since_first_transaction,
	sum(active_customers) as active_customers,
	sum(cohort_size) as total_cohort_size,
	round(
		sum(active_customers)::numeric / sum(cohort_size) * 100,
		2
	) as weighted_retention_rate
from cohort_with_size_by_card_group
where months_since_first_transaction in (1, 3, 6, 12)
group by
	card_group,
	months_since_first_transaction
order by
	card_group,
	months_since_first_transaction;

	