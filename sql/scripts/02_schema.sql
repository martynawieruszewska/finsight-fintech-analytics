/*
===============================================================================
FinSight - Database Schema
===============================================================================
Purpose:
    - Creates schemas and tables required for the FinSight analytical model.
    - Separates loaded processed data from the dimensional analytics layer.

Schemas:
    1. staging   - cleaned source data loaded from Parquet files
    2. analytics - dimensional model used for analysis and reporting

Model:
    - analytics.fact_transactions
    - analytics.dim_users
    - analytics.dim_cards
    - analytics.dim_mcc
    - analytics.dim_date
===============================================================================
*/
-- Optional development reset:
-- DROP SCHEMA IF EXISTS staging CASCADE;
-- DROP SCHEMA IF EXISTS analytics CASCADE;

create schema if not exists staging;
create schema if not exists analytics;

-- =============================================================================
-- Staging Tables
-- =============================================================================

-- Foreign key constraints are intentionally omitted from the staging layer.
-- Referential integrity is validated before loading and will be enforced
-- in the analytics dimensional model.

create table if not exists staging.users (
    id integer primary key,
    current_age integer,
    retirement_age integer,
    birth_year integer,
    birth_month integer,
    gender varchar(20),
    address text,
    latitude double PRECISION,
    longitude double PRECISION,
    per_capita_income numeric(12, 2),
    yearly_income numeric(12, 2),
    total_debt numeric(12, 2),
    credit_score integer,
    num_credit_cards integer
);

create table if not exists staging.transactions (
    id integer primary key,
    date timestamp,
    client_id integer,
    card_id integer,
    amount numeric(12, 2),
    use_chip varchar(50),
    merchant_id integer,
    merchant_city varchar(100),
    merchant_state varchar(100),
    zip double PRECISION,
    mcc integer,
    errors varchar(255)
);

create table if not exists staging.cards (
    id integer primary key,
    client_id integer,
    card_brand varchar(100),
    card_type varchar(50),
    card_number bigint,
    expires date,
    cvv integer,
    has_chip boolean,
    num_cards_issued integer,
    credit_limit numeric(12, 2),
    acct_open_date date,
    year_pin_last_changed integer,
    card_on_dark_web boolean
);

create table if not exists staging.mcc_codes (
    mcc integer primary key,
    description varchar(255)
);

create table if not exists staging.fraud_labels (
    transaction_id integer primary key,
    is_fraud boolean
);
