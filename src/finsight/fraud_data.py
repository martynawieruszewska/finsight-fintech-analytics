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