/*
===============================================================================
FinSight - RFM Segmentation
===============================================================================
Purpose:
    - Segments customers based on Recency, Frequency, and Monetary value.
    - Identifies customer groups with different levels of activity and value.
    - Uses Customer 360 metrics as the foundation for customer segmentation.
    - Creates a reusable customer-level RFM analytical view.
===============================================================================
*/


-- =============================================================================
-- 1. RFM Base Metrics
-- =============================================================================
-- Only customers with transaction history are included in RFM analysis.

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
-- Initial distribution analysis used to evaluate appropriate scoring methods.

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
-- Standard quintile scoring is not appropriate for Recency because the
-- distribution contains a large number of tied values at recency = 0.
-- Custom thresholds are therefore used to avoid assigning different scores
-- to customers with identical Recency values.

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


-- Validate custom Recency scoring.

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
-- Frequency shows sufficient variation for quintile-based scoring.
-- Higher transaction frequency corresponds to a higher F score.

select
	percentile_cont(0.2) within group (order by transaction_count) as p20_frequency,
	percentile_cont(0.4) within group (order by transaction_count) as p40_frequency,
	percentile_cont(0.6) within group (order by transaction_count) as p60_frequency,
	percentile_cont(0.8) within group (order by transaction_count) as p80_frequency
from analytics.customer_360
where transaction_count is not null;


-- =============================================================================
-- 5. Monetary Analysis
-- =============================================================================
-- Monetary value shows sufficient variation for quintile-based scoring.
-- Higher total spending corresponds to a higher M score.

select
	percentile_cont(0.2) within group (order by gross_total_spend) as p20_monetary,
	percentile_cont(0.4) within group (order by gross_total_spend) as p40_monetary,
	percentile_cont(0.6) within group (order by gross_total_spend) as p60_monetary,
	percentile_cont(0.8) within group (order by gross_total_spend) as p80_monetary
from analytics.customer_360
where transaction_count is not null;


-- =============================================================================
-- 6. Customer RFM View
-- =============================================================================
-- Grain: one row per customer with transaction history.
--
-- Scoring methodology:
--     R: custom thresholds due to highly concentrated Recency distribution.
--     F: quintile-based scoring using transaction frequency.
--     M: quintile-based scoring using gross transaction value.

create or replace view analytics.customer_rfm as

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

		ntile(5) over (
			order by transaction_count
		) as f_score,

		ntile(5) over (
			order by gross_total_spend
		) as m_score

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
	*,
	case
		when r_score >= 4
			and f_score >= 4
			and m_score >= 4
			then 'champions'

		when r_score >= 4
			and f_score >= 3
			and m_score >= 3
			then 'loyal customers'

		when r_score >= 4
			and f_score <= 2
			and m_score <= 2
			then 'new / promising'

		when r_score >= 4
			then 'active customers'

		when r_score = 3
			then 'need attention'

		when r_score <= 2
			and f_score >= 4
			and m_score >= 4
			then 'at risk'

		when r_score <= 2
			and f_score <= 2
			and m_score <= 2
			then 'hibernating'

		else 'low engagement'
	end as customer_segment

from rfm_codes;


-- =============================================================================
-- 7. RFM View Validation
-- =============================================================================

-- Validate total number of customers included in RFM.

select
	count(*) as rfm_customers
from analytics.customer_rfm;


-- Validate RFM score ranges.

select
	min(r_score) as min_r_score,
	max(r_score) as max_r_score,
	min(f_score) as min_f_score,
	max(f_score) as max_f_score,
	min(m_score) as min_m_score,
	max(m_score) as max_m_score
from analytics.customer_rfm;


-- Validate customer distribution across segments.

select
	customer_segment,
	count(*) as customer_count,
	round(
		count(*) * 100.0 / sum(count(*)) over (),
		2
	) as customer_percentage
from analytics.customer_rfm
group by customer_segment
order by customer_count desc;


-- Validate distribution of RFM score combinations.

select
	r_score,
	f_score,
	m_score,
	count(*) as customer_count
from analytics.customer_rfm
group by
	r_score,
	f_score,
	m_score
order by customer_count desc;