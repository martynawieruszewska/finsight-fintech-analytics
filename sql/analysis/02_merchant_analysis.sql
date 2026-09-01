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


-- =============================================================================
-- Transaction Volume by Merchant Category
-- =============================================================================
-- identifies merchant categories generating the highest number of transactions

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
order by transaction_count desc;


-- =============================================================================
-- Gross Transaction Value by Merchant Category
-- =============================================================================
-- identifies merchant categories generating the highest gross transaction value

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
order by gross_transaction_value desc;


-- =============================================================================
-- Average Ticket by Merchant Category
-- =============================================================================
-- compares the average value of positive transactions across merchant categories
-- transaction count is included to provide context for categories with small samples

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


-- =============================================================================
-- Fraud Rate by Merchant Category
-- =============================================================================
-- calculates fraud rate among transactions with known fraud labels
-- only categories with at least 10,000 labeled transactions are included
-- to reduce the impact of unstable rates from very small samples

select
	m.mcc, 
	m.description,
	count(*) as transaction_count,
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as avg_ticket,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	count(*) filter (where is_fraud is true) as fraud_transactions,
	round(
		(count(*) filter (where is_fraud is true))::numeric
		/
		(count(*) filter (where is_fraud is not null))::numeric
		* 100,
		2
	) as fraud_rate
from analytics.fact_transactions t
left join analytics.dim_mcc m
	on t.mcc_key = m.mcc_key 
group by 
	m.mcc_key,
	m.description
having count(*) filter (where is_fraud is not null) >= 10000
order by fraud_rate desc;


-- =============================================================================
-- Fraud Volume by Merchant Category
-- =============================================================================
-- identifies merchant categories generating the highest absolute number
-- of fraudulent transactions

select
	m.mcc, 
	m.description,
	count(*) as transaction_count,
	sum(amount) filter (where amount > 0) as gross_transaction_value,
	round(avg(amount) filter (where amount > 0), 2) as avg_ticket,
	count(*) filter (where is_fraud is not null) as labeled_transactions,
	count(*) filter (where is_fraud is true) as fraud_transactions,
	round(
		(count(*) filter (where is_fraud is true))::numeric
		/
		(count(*) filter (where is_fraud is not null))::numeric
		* 100,
		2
	) as fraud_rate
from analytics.fact_transactions t
left join analytics.dim_mcc m
	on t.mcc_key = m.mcc_key 
group by 
	m.mcc_key,
	m.description
having count(*) filter (where is_fraud is not null) >= 10000
order by fraud_transactions desc;