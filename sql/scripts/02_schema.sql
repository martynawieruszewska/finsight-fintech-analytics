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

-- =============================================================================
-- Analytics Tables
-- =============================================================================

create table if not exists analytics.dim_users (
    user_key bigserial primary key,
    user_id integer unique not null,
    current_age integer,
    retirement_age integer,
    birth_year integer,
    birth_month integer,
    gender varchar(20),
    address text,
    latitude double precision,
    longitude double precision,
    per_capita_income numeric(12, 2),
    yearly_income numeric(12, 2),
    total_debt numeric(12, 2),
    credit_score integer,
    num_credit_cards integer
);

create table if not exists analytics.dim_cards (
    card_key bigserial primary key,
    card_id integer unique not null,
    user_key bigint not null,
    card_brand varchar(100),
    card_type varchar(50),
    expires date,
    has_chip boolean,
    num_cards_issued integer,
    credit_limit numeric(12, 2),
    acct_open_date date,
    year_pin_last_changed integer,
    card_on_dark_web boolean,

    constraint fk_dim_cards_user
        foreign key (user_key)
        references analytics.dim_users(user_key)
);

create table if not exists analytics.dim_mcc (
    mcc_key bigserial primary key,
    mcc integer unique not null,
    description varchar(255)
);

create table if not exists analytics.dim_date (
    date_key integer primary key,
    full_date date unique not null,
    year integer not null,
    quarter integer not null,
    month integer not null,
    month_name varchar(20) not null,
    day integer not null,
    day_of_week integer not null,
    day_name varchar(20) not null,
    is_weekend boolean not null
);

create table if not exists analytics.fact_transactions (
    transaction_key bigserial primary key,
    transaction_id integer unique not null,
    user_key bigint not null,
    card_key bigint not null,
    mcc_key bigint not null,
    date_key integer not null,
    transaction_timestamp timestamp not null,
    amount numeric(12, 2) not null,
    use_chip varchar(50),
    merchant_id integer,
    merchant_city varchar(100),
    merchant_state varchar(100),
    zip double precision,
    errors varchar(255),
    is_fraud boolean,

    constraint fk_fact_transactions_user
        foreign key (user_key)
        references analytics.dim_users(user_key),

    constraint fk_fact_transactions_card
        foreign key (card_key)
        references analytics.dim_cards(card_key),

    constraint fk_fact_transactions_mcc
        foreign key (mcc_key)
        references analytics.dim_mcc(mcc_key),

    constraint fk_fact_transactions_date
        foreign key (date_key)
        references analytics.dim_date(date_key)
);