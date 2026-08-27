/*
===============================================================================
FinSight - Analytics Layer Load
===============================================================================
Purpose:
    - Loads the dimensional analytics model from the staging layer.
    - Transforms source identifiers into analytics surrogate keys.
    - Populates dimensions before loading the transaction fact table.
    - Supports a full reload of the analytics layer.

Load order:
    1. dim_users
    2. dim_cards
    3. dim_mcc
    4. dim_date
    5. fact_transactions
===============================================================================
*/


-- =============================================================================
-- Reset Analytics Layer
-- =============================================================================

-- Tables are truncated before each full reload.
-- restart identity resets surrogate key sequences.
-- cascade handles foreign key dependencies between analytics tables.

truncate table
    analytics.fact_transactions,
    analytics.dim_cards,
    analytics.dim_users,
    analytics.dim_mcc,
    analytics.dim_date
restart identity cascade;


-- =============================================================================
-- Load dim_users
-- =============================================================================

insert into analytics.dim_users (
    user_id,
    current_age,
    retirement_age,
    birth_year,
    birth_month,
    gender,
    address,
    latitude,
    longitude,
    per_capita_income,
    yearly_income,
    total_debt,
    credit_score,
    num_credit_cards
)
select
    id,
    current_age,
    retirement_age,
    birth_year,
    birth_month,
    gender,
    address,
    latitude,
    longitude,
    per_capita_income,
    yearly_income,
    total_debt,
    credit_score,
    num_credit_cards
from staging.users;


-- =============================================================================
-- Load dim_cards
-- =============================================================================

insert into analytics.dim_cards (
    card_id,
    user_key,
    card_brand,
    card_type,
    expires,
    has_chip,
    num_cards_issued,
    credit_limit,
    acct_open_date,
    year_pin_last_changed,
    card_on_dark_web
)
select
    c.id,
    u.user_key,
    c.card_brand,
    c.card_type,
    c.expires,
    c.has_chip,
    c.num_cards_issued,
    c.credit_limit,
    c.acct_open_date,
    c.year_pin_last_changed,
    c.card_on_dark_web
from staging.cards c
join analytics.dim_users u
    on c.client_id = u.user_id;


-- =============================================================================
-- Load dim_mcc
-- =============================================================================

insert into analytics.dim_mcc (
    mcc,
    description
)
select
    mcc,
    description
from staging.mcc_codes;


-- =============================================================================
-- Load dim_date
-- =============================================================================

insert into analytics.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    is_weekend
)
select
    to_char(d.full_date, 'yyyymmdd')::integer as date_key,
    d.full_date,
    extract(year from d.full_date)::integer as year,
    extract(quarter from d.full_date)::integer as quarter,
    extract(month from d.full_date)::integer as month,
    trim(to_char(d.full_date, 'month')) as month_name,
    extract(day from d.full_date)::integer as day,
    extract(isodow from d.full_date)::integer as day_of_week,
    trim(to_char(d.full_date, 'day')) as day_name,
    extract(isodow from d.full_date) in (6, 7) as is_weekend
from generate_series(
    (select min(date)::date from staging.transactions),
    (select max(date)::date from staging.transactions),
    interval '1 day'
) as d(full_date);


-- =============================================================================
-- Load fact_transactions
-- =============================================================================

insert into analytics.fact_transactions (
    transaction_id,
    user_key,
    card_key,
    mcc_key,
    date_key,
    transaction_timestamp,
    amount,
    use_chip,
    merchant_id,
    merchant_city,
    merchant_state,
    zip,
    errors,
    is_fraud
)
select
    t.id,
    u.user_key,
    c.card_key,
    m.mcc_key,
    d.date_key,
    t.date,
    t.amount,
    t.use_chip,
    t.merchant_id,
    t.merchant_city,
    t.merchant_state,
    t.zip,
    t.errors,
    f.is_fraud
from staging.transactions t
join analytics.dim_users u
    on t.client_id = u.user_id
join analytics.dim_cards c
    on t.card_id = c.card_id
join analytics.dim_mcc m
    on t.mcc = m.mcc
join analytics.dim_date d
    on t.date::date = d.full_date
left join staging.fraud_labels f
    on t.id = f.transaction_id;