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





