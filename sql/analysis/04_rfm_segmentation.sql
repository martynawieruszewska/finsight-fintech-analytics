/*
===============================================================================
FinSight - RFM Segmentation
===============================================================================
Purpose:
    - Segments customers based on Recency, Frequency, and Monetary value.
    - Identifies customer groups with different levels of activity and value.
    - Uses Customer 360 metrics as the foundation for customer segmentation.
===============================================================================
*/

-- =============================================================================
-- 1. RFM Base Metrics
-- =============================================================================

select 
	user_key,
	recency_days as recency,
	transaction_count as frequency,
	gross_total_spend as monetary
from analytics.customer_360
where transaction_count is not null;


-- =============================================================================
-- 2. RFM Distribution Overview
-- =============================================================================

select
	min(recency_days) as min_recency,
	round(avg(recency_days), 2) as avg_recency,
	max(recency_days) as max_recency,

	min(transaction_count) as min_frequency,
	round(avg(transaction_count), 2) as avg_frequency,
	max(transaction_count) as max_frequency,

	min(gross_total_spend) as min_monetary,
	round(avg(gross_total_spend), 2) as avg_monetary,
	max(gross_total_spend) as max_monetary
from analytics.customer_360
where transaction_count is not null;


-- =============================================================================
-- 3. Recency Analysis
-- =============================================================================

select
	percentile_cont(0.2) within group (order by recency_days) as p20_recency,
	percentile_cont(0.4) within group (order by recency_days) as p40_recency,
	percentile_cont(0.6) within group (order by recency_days) as p60_recency,
	percentile_cont(0.8) within group (order by recency_days) as p80_recency
from analytics.customer_360
where transaction_count is not null;

select
	recency_days,
	count(*) as customer_count
from analytics.customer_360
where transaction_count is not null
group by recency_days
order by recency_days;

with rfm_recency as (
	select
		user_key,
		recency_days as recency,
		case
			when recency_days = 0 then 5
			when recency_days = 1 then 4
			when recency_days = 2 then 3
			when recency_days between 3 and 5 then 2
			else 1
		end as r_score
	from analytics.customer_360
	where transaction_count is not null
)

select
	r_score,
	count(*) as customer_count
from rfm_recency
group by r_score
order by r_score desc;


-- =============================================================================
-- 4. Frequency Analysis
-- =============================================================================

select
	percentile_cont(0.2) within group (order by transaction_count) as p20_frequency,
	percentile_cont(0.4) within group (order by transaction_count) as p40_frequency,
	percentile_cont(0.6) within group (order by transaction_count) as p60_frequency,
	percentile_cont(0.8) within group (order by transaction_count) as p80_frequency
from analytics.customer_360
where transaction_count is not null;

with rfm_frequency as (
	select
		user_key,
		transaction_count as frequency,
		ntile(5) over (order by transaction_count) as f_score
	from analytics.customer_360
	where transaction_count is not null
)

select
	f_score,
	count(*) as customer_count
from rfm_frequency
group by f_score
order by f_score;


-- =============================================================================
-- 5. Monetary Analysis
-- =============================================================================

select
	percentile_cont(0.2) within group (order by gross_total_spend) as p20_monetary,
	percentile_cont(0.4) within group (order by gross_total_spend) as p40_monetary,
	percentile_cont(0.6) within group (order by gross_total_spend) as p60_monetary,
	percentile_cont(0.8) within group (order by gross_total_spend) as p80_monetary
from analytics.customer_360
where transaction_count is not null;

with rfm_monetary as (
	select
		user_key,
		gross_total_spend as monetary,
		ntile(5) over (order by gross_total_spend) as m_score
	from analytics.customer_360
	where transaction_count is not null
)

select
	m_score,
	count(*) as customer_count
from rfm_monetary
group by m_score
order by m_score;

-- =============================================================================
-- 6. Final RFM Scores
-- =============================================================================

with rfm_scores as (
	select
		user_key,
		recency_days as recency,
		transaction_count as frequency,
		gross_total_spend as monetary,

		case
			when recency_days = 0 then 5
			when recency_days = 1 then 4
			when recency_days = 2 then 3
			when recency_days between 3 and 5 then 2
			else 1
		end as r_score,
		ntile(5) over (order by transaction_count) as f_score,
		ntile(5) over (order by gross_total_spend) as m_score
	from analytics.customer_360
	where transaction_count is not null
),

rfm_codes as (
	select
	*,
	concat(r_score, f_score, m_score) as rfm_code
	from rfm_scores
)
select 
	*
from rfm_codes
order by user_key;

