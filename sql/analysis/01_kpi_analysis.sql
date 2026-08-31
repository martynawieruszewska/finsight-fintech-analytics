/*
===============================================================================
FinSight - KPI Analysis
===============================================================================
Purpose:
    - Calculates key business metrics describing customer activity.
    - Measures transaction frequency, value, and fraud.
===============================================================================
*/

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
	