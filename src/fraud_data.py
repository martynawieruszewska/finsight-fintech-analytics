import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# Create database engine
def connect_to_database():
    load_dotenv()

    engine = create_engine(
        f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
        f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
    )

    with engine.connect():
        print("Connected!")

    return engine


# Split dataframe into features and target
def get_data(df):
    X = df.drop(
        columns=[
            "transaction_key",
            "transaction_timestamp",
            "is_fraud"
        ]
    )

    y = df["is_fraud"]

    return X, y


# Load training data
def download_train_data(engine, non_fraud_limit=300000):
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

    X_train, y_train = get_data(train_df)

    return X_train, y_train


# Load validation data
def download_validation_data(engine):
    val_query = """
        select *
        from analytics.fraud_ml_features
        where transaction_timestamp >= '2018-01-01'
          and transaction_timestamp < '2019-01-01'
    """

    val_df = pd.read_sql(val_query, engine)

    X_val, y_val = get_data(val_df)

    return X_val, y_val