/*
===============================================================================
FinSight - Fraud Detection ML Feature View
===============================================================================
Purpose:
    - Creates the analytics.fraud_ml_features materialized view used by all
      fraud detection notebooks.
    - Defines the ML observation unit as a single transaction.
    - Uses only information available before each transaction.
    - Historical features are calculated on all transactions, while only
      transactions with a known fraud label are kept in the final view.

Run after:
    - 03_load_analytics.sql
    - 04_indexes.sql
===============================================================================
*/

drop materialized view if exists analytics.fraud_ml_features;

create materialized view analytics.fraud_ml_features as

with transaction_features as (
	select
		transaction_key,
		user_key,
		card_key,
		amount,
		mcc_key,
		use_chip,
		merchant_id,
		transaction_timestamp,
		extract(hour from transaction_timestamp) as transaction_hour,
		extract(dow from transaction_timestamp) as day_of_week,
		case
			when extract(dow from transaction_timestamp) in (0, 6) then 1
			else 0
		end as is_weekend,
		is_fraud
	from analytics.fact_transactions
),

historical_features as (
	select 
		*,
		count(*) over (partition by user_key order by transaction_timestamp, transaction_key rows between unbounded preceding and 1 preceding) as user_previous_transaction_count,
		round(avg(amount) over (partition by user_key order by transaction_timestamp, transaction_key rows between unbounded preceding and 1 preceding), 2) as user_previous_avg_amount,
		count(*) over (partition by user_key order by transaction_timestamp range between interval '24 hours' preceding and interval '1 microsecond' preceding) as user_transactions_last_24h,
		round(sum(amount) over (partition by user_key order by transaction_timestamp range between interval '24 hours' preceding and interval '1 microsecond' preceding), 2) as user_amount_last_24h,
		count(*) over (partition by card_key order by transaction_timestamp, transaction_key rows between unbounded preceding and 1 preceding) as card_previous_transaction_count,
		round(avg(amount) over (partition by card_key order by transaction_timestamp, transaction_key rows between unbounded preceding and 1 preceding), 2) as card_previous_avg_amount,
		lag(transaction_timestamp) over (partition by user_key order by transaction_timestamp, transaction_key) as user_previous_transaction_timestamp,
		lag(transaction_timestamp) over (partition by card_key order by transaction_timestamp, transaction_key) as card_previous_transaction_timestamp
	from transaction_features
), 

ml_features as (

select 
	transaction_key,
	transaction_timestamp,
	
	-- transaction features
	amount,
	mcc_key,
	use_chip,
	merchant_id,
	transaction_hour,
	day_of_week,
	is_weekend,
	
	-- user features
	user_previous_transaction_count,
	user_previous_avg_amount,
	round(amount - user_previous_avg_amount, 2) as amount_vs_user_avg,
	user_transactions_last_24h,
    user_amount_last_24h,
    round(extract(epoch from (transaction_timestamp - user_previous_transaction_timestamp)) / 3600, 2) as hours_since_user_transaction,
	
	-- card historical features
	card_previous_transaction_count,
	card_previous_avg_amount,
	round(amount - card_previous_avg_amount, 2) as amount_vs_card_avg,
	round(extract(epoch from (transaction_timestamp - card_previous_transaction_timestamp)) / 3600, 2) as hours_since_card_transaction,
	
	-- target
	is_fraud
from historical_features
where is_fraud is not null
)

select 
	*
from ml_features;

