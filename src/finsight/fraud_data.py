import pandas as pd
from sqlalchemy import text


BASE_FEATURES = [
    "amount",
    "mcc_key",
    "use_chip",
    "merchant_id",
    "transaction_hour",
    "day_of_week",
    "is_weekend",
    "user_previous_transaction_count",
    "user_previous_avg_amount",
    "amount_vs_user_avg",
    "card_previous_transaction_count",
    "card_previous_avg_amount",
    "amount_vs_card_avg",
]

BEHAVIORAL_FEATURES = [
    "user_transactions_last_24h",
    "user_amount_last_24h",
    "hours_since_user_transaction",
    "hours_since_card_transaction",
]


# Split dataframe into features and target
def split_features_target(df, features):
    X = df[features].copy()
    y = df["is_fraud"]

    return X, y


# Load training data
def download_train_data(engine, non_fraud_limit=300000, features=BASE_FEATURES):
    train_query = text("""
        (
            select *
            from analytics.fraud_ml_features
            where transaction_timestamp < '2018-01-01'
              and is_fraud = true
        )
        union all
        (
            select *
            from analytics.fraud_ml_features
            where transaction_timestamp < '2018-01-01'
              and is_fraud = false
            order by md5(transaction_key::text), transaction_key
            limit :non_fraud_limit
        )
    """)

    train_df = pd.read_sql(
        train_query,
        engine,
        params={"non_fraud_limit": non_fraud_limit}
    )

    X_train, y_train = split_features_target(train_df, features)

    return X_train, y_train


# Load validation data
def download_validation_data(engine, features=BASE_FEATURES):
    val_query = """
        select *
        from analytics.fraud_ml_features
        where transaction_timestamp >= '2018-01-01'
          and transaction_timestamp < '2019-01-01'
    """

    val_df = pd.read_sql(val_query, engine)

    X_val, y_val = split_features_target(val_df, features)

    return X_val, y_val


# Get non-fraud counts by year
def get_non_fraud_counts(engine, start_year, end_year):
    query = text("""
        select
            extract(year from transaction_timestamp)::int as year,
            count(*) as non_fraud_count
        from analytics.fraud_ml_features
        where is_fraud = false
          and extract(year from transaction_timestamp) between :start_year and :end_year
        group by extract(year from transaction_timestamp)
        order by year
    """)

    counts_df = pd.read_sql(
        query,
        engine,
        params={"start_year": start_year, "end_year": end_year}
    )

    return dict(zip(counts_df["year"], counts_df["non_fraud_count"]))


# Calculate proportional non-fraud sample limits
def calculate_year_limits(non_fraud_counts, total_limit=300000):
    total_non_fraud = sum(non_fraud_counts.values())
    year_limits = {}

    for year, count in non_fraud_counts.items():
        proportion = count / total_non_fraud
        year_limits[year] = round(proportion * total_limit)

    return year_limits


# Load data for a specific year
def download_year_data(engine, year, non_fraud_limit, features=BASE_FEATURES):
    year_query = text("""
        (
            select *
            from analytics.fraud_ml_features
            where extract(year from transaction_timestamp) = :year
              and is_fraud = true
        )
        union all
        (
            select *
            from analytics.fraud_ml_features
            where extract(year from transaction_timestamp) = :year
              and is_fraud = false
            order by md5(transaction_key::text), transaction_key
            limit :non_fraud_limit
        )
    """)

    year_df = pd.read_sql(
        year_query,
        engine,
        params={"year": year, "non_fraud_limit": non_fraud_limit}
    )

    X_year, y_year = split_features_target(year_df, features)

    return X_year, y_year


# Load yearly development data with proportional sampling
def download_yearly_data(engine, start_year, end_year, total_non_fraud_limit=300000, features=BASE_FEATURES):
    non_fraud_counts = get_non_fraud_counts(engine, start_year, end_year)
    year_limits = calculate_year_limits(non_fraud_counts, total_non_fraud_limit)

    yearly_data = {}

    for year in range(start_year, end_year + 1):
        X_year, y_year = download_year_data(
            engine,
            year,
            year_limits[year],
            features
        )

        yearly_data[year] = {
            "X": X_year,
            "y": y_year
        }

    return yearly_data