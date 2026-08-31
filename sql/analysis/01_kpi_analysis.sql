/*
===============================================================================
FinSight - KPI Analysis
===============================================================================
Purpose:
    - Calculates key business metrics describing customer activity.
    - Measures transaction frequency, value, and fraud.
===============================================================================
*/

select
*
from analytics.fact_transactions;

-- =============================================================================
-- Active Users
-- =============================================================================

select 
count(distinct user_key) as active_users
from analytics.fact_transactions; 

select 
	month,
	active_users,
	difference,
case 
	when difference > 0 then '+'
	when difference = 0 then '0'
	when difference < 0 then '-'
	else 'n/a'
end as trend,
	round((difference::numeric / (lag(active_users) over (order by month)))*100, 2) as percentage_change
from (
with monthly_active_users as (
select 
	date_trunc('month', transaction_timestamp) as month,
	count(distinct user_key) as active_users
from analytics.fact_transactions
group by date_trunc('month', transaction_timestamp)
)

select 
	month,
	active_users,
	active_users - lag(active_users) over(order by month) as difference
from monthly_active_users
	)t;

-- =============================================================================
-- Transaction Frequency
-- =============================================================================

select
	month, 	
	transactions,
	active_users,
	transactions_per_user,
	difference,
	round((difference::numeric / (lag(transactions_per_user) over(order by month))::numeric)*100, 2) as percentage_change
from (
with monthly_transaction_frequency as (
select
	date_trunc('month', transaction_timestamp) as month,
	count(transaction_key) as transactions,
	count(distinct user_key) as active_users,
	round(count(transaction_key)::numeric/count(distinct user_key)::numeric, 2) as transactions_per_user
from analytics.fact_transactions
group by date_trunc('month', transaction_timestamp)
)

select 
	month, 	
	transactions,
	active_users,
	transactions_per_user,
	transactions_per_user - lag(transactions_per_user) over(order by month) as difference
from monthly_transaction_frequency
)t

-- =============================================================================
-- Transaction Value
-- =============================================================================

select
	transactions,
	negative_transactions,
	round(negative_transactions::numeric / transactions::numeric*100, 2) as negative_percentage
from (
select 
	count(*) as transactions,
	count(*) filter (where amount < 0) as negative_transactions
from analytics.fact_transactions
)t;

-- Negative Transaction Analysis

select
	user_key,
    transaction_id,
    transaction_timestamp,
    amount,
    merchant_id,
    mcc_key
from analytics.fact_transactions
where user_key = 1982 and merchant_id = 59935
order by transaction_timestamp;

-- Gross Transaction Value
-- Calculates the total value of positive transactions only.
-- Negative transactions are excluded because they may represent refunds or reversals.

select 
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	sum(amount) as net_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as average_transaction_value
from analytics.fact_transactions;

-- Monthly Transaction Value

select 
	date_trunc('month', transaction_timestamp) as month,
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	sum(amount) as net_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as average_transaction_value
from analytics.fact_transactions
group by date_trunc('month', transaction_timestamp);

-- Transaction Date Range
-- Checks whether the first and last months contain complete transaction data.

select 
	min(transaction_timestamp) as min_transaction_date,
	max(transaction_timestamp) as max_transaction_date
from analytics.fact_transactions 

-- Monthly Transaction Value Trend
-- Analyzes month-to-month changes in net transaction value
-- and average transaction value.

select 
	month,
	gross_transaction_value,
	gross_value_difference,
	net_transaction_value,
	net_value_difference,
	round(net_value_difference::numeric / lag(net_transaction_value) over (order by month)*100, 2) as net_value_percentage_change,
	average_transaction_value,
	average_value_difference,
	round(average_value_difference::numeric / lag(average_transaction_value) over (order by month)*100, 2) as average_value_percentage_change
from (
with monthly_transaction_value as (
select 
	date_trunc('month', transaction_timestamp) as month,
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	sum(amount) as net_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as average_transaction_value
from analytics.fact_transactions
group by date_trunc('month', transaction_timestamp)
)

select 
	month,
	gross_transaction_value,
	gross_transaction_value - lag(gross_transaction_value) over(order by month) as gross_value_difference,
	net_transaction_value,
	net_transaction_value - lag(net_transaction_value) over(order by month) as net_value_difference,
	average_transaction_value,
	average_transaction_value - lag(average_transaction_value) over(order by month) as average_value_difference
from monthly_transaction_value
)t
order by month;

-- =============================================================================
-- Transaction Value Seasonality Analysis
-- =============================================================================
-- investigates recurring monthly patterns in transaction value
-- and checks whether they are explained by differences in month length

with monthly_net_value as (
select 
	date_trunc('month', transaction_timestamp) as month,
	sum(amount) as net_transaction_value,
	count(distinct date_trunc('day', transaction_timestamp)) as days_in_month
from analytics.fact_transactions 
group by date_trunc('month', transaction_timestamp)
)

select 
	month,
	net_transaction_value,
	days_in_month,
	round(net_transaction_value / days_in_month, 2) as average_daily_net_value
from monthly_net_value;

-- =============================================================================
-- Fraud Rate
-- =============================================================================

select 
	total_transactions,
	labeled_transactions,
	fraud_transactions,
	round(((labeled_transactions::numeric / total_transactions::numeric) * 100), 2) as labeled_percentage,
	round(((fraud_transactions::numeric / labeled_transactions::numeric) * 100), 2) as fraud_rate,
	round(((fraud_transactions::numeric / total_transactions::numeric) * 100), 2) as fraud_percentage_of_total
from (
select 
	count(*) as total_transactions,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	count(*) filter (where is_fraud is True) as fraud_transactions
from analytics.fact_transactions
)t;

-- =============================================================================
-- Fraud Label Coverage Over Time
-- =============================================================================

select 
	month,
	total_transactions,
	labeled_transactions,
	fraud_transactions,
	round(((labeled_transactions::numeric / total_transactions::numeric) * 100), 2) as labeled_percentage,
	round(((fraud_transactions::numeric / labeled_transactions::numeric) * 100), 2) as fraud_rate,
	round(((fraud_transactions::numeric / total_transactions::numeric) * 100), 2) as fraud_percentage_of_total
from (
select 
	date_trunc('month', transaction_timestamp) as month,
	count(*) as total_transactions,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	count(*) filter (where is_fraud is True) as fraud_transactions
from analytics.fact_transactions
group by date_trunc('month', transaction_timestamp)
)t
order by month;

select 
	day,
	total_transactions,
	labeled_transactions,
	fraud_transactions,
	round(((labeled_transactions::numeric / total_transactions::numeric) * 100), 2) as labeled_percentage,
	round(((fraud_transactions::numeric / labeled_transactions::numeric) * 100), 2) as fraud_rate,
	round(((fraud_transactions::numeric / total_transactions::numeric) * 100), 2) as fraud_percentage_of_total
from (
select 
	date_trunc('day', transaction_timestamp) as day,
	count(*) as total_transactions,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	count(*) filter (where is_fraud is True) as fraud_transactions
from analytics.fact_transactions
group by date_trunc('day', transaction_timestamp)
)t
order by month;

select
	is_fraud,
	round(avg(amount), 2) as average_transaction_value,
	min(amount) as min_transaction_value,
	max(amount) as max_transaction_value,
	percentile_cont(0.25) within group (order by amount) as q1,
	percentile_cont(0.5) within group (order by amount) as median_transaction_value,
	percentile_cont(0.75) within group (order by amount) as q3
from analytics.fact_transactions
where amount > 0 and is_fraud is not null
group by is_fraud;

-- =============================================================================
-- Cards per User
-- =============================================================================

with cards_per_user as (
	select 
		user_key,
		count(card_key) as number_of_cards
	from analytics.dim_cards
	group by user_key
)

select
	round(avg(number_of_cards), 2) as average_cards_per_user
from cards_per_user;


with cards_per_user as (
	select 
		user_key,
		count(card_key) as number_of_cards
	from analytics.dim_cards
	group by user_key
)

select
	number_of_cards,
	count(*) as users,
	round(count(*)::numeric / sum(count(*)) over () * 100, 2) as percentage_of_users
from cards_per_user
group by number_of_cards
order by number_of_cards;

