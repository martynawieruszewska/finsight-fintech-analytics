/*
===============================================================================
FinSight - Merchant Category Analysis
===============================================================================
Purpose:
    - Analyzes transaction activity across merchant categories.
    - Identifies categories with the highest transaction volume and value.
    - Compares average transaction value and fraud activity by merchant category.
===============================================================================
*/

select
*
from analytics.dim_mcc
limit 10;

select
	m.mcc, 
	m.description,
	count(*) as transaction_count,
	sum(amount) filter (where amount > 0) as gross_transaction_value
from analytics.fact_transactions t
left join analytics.dim_mcc m
on t.mcc_key = m.mcc_key 
group by 
	m.mcc_key,
	m.description
order by count(*) desc;

select
	m.mcc, 
	m.description,
	count(*) as transaction_count,
	sum(amount) filter (where amount > 0) as gross_transaction_value
from analytics.fact_transactions t
left join analytics.dim_mcc m
on t.mcc_key = m.mcc_key 
group by 
	m.mcc_key,
	m.description
order by sum(amount) filter (where amount > 0) desc;

select
	m.mcc, 
	m.description,
	count(*) as transaction_count,
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as avg_ticket
from analytics.fact_transactions t
left join analytics.dim_mcc m
on t.mcc_key = m.mcc_key 
group by 
	m.mcc_key,
	m.description
order by avg_ticket desc;