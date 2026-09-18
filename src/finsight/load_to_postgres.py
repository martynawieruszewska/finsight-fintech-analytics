from pathlib import Path
import os
import time

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# --- Paths ---

project_root = Path(__file__).resolve().parent.parent
env_path = project_root / ".env"
processed_path = project_root / "data" / "processed"


# --- Environment Variables ---

load_dotenv(env_path)

db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")


# --- Database Connection ---

database_url = (
    f"postgresql+psycopg2://{db_user}:{db_password}"
    f"@{db_host}:{db_port}/{db_name}"
)

engine = create_engine(database_url)

with engine.connect() as connection:
    result = connection.execute(
        text("SELECT current_database();")
    )

    print(f"Connected to PostgreSQL database: {result.scalar()}")


# --- Load Processed Data ---

users = pd.read_parquet(
    processed_path / "users.parquet"
)

cards = pd.read_parquet(
    processed_path / "cards.parquet"
)

transactions = pd.read_parquet(
    processed_path / "transactions.parquet"
)

mcc_codes = pd.read_parquet(
    processed_path / "mcc_codes.parquet"
)

fraud_labels = pd.read_parquet(
    processed_path / "fraud_labels.parquet"
)

print(f"Loaded users.parquet: {len(users):,} rows")
print(f"Loaded cards.parquet: {len(cards):,} rows")
print(f"Loaded transactions.parquet: {len(transactions):,} rows")
print(f"Loaded mcc_codes.parquet: {len(mcc_codes):,} rows")
print(f"Loaded fraud_labels.parquet: {len(fraud_labels):,} rows")


# --- Full Staging Reload ---

reload_start = time.perf_counter()

with engine.begin() as connection:
    connection.execute(
        text("""
            TRUNCATE TABLE
                staging.users,
                staging.cards,
                staging.transactions,
                staging.mcc_codes,
                staging.fraud_labels;
        """)
    )


# --- Load Data into PostgreSQL ---

users.to_sql(
    name="users",
    con=engine,
    schema="staging",
    if_exists="append",
    index=False
)

cards.to_sql(
    name="cards",
    con=engine,
    schema="staging",
    if_exists="append",
    index=False
)

mcc_codes.to_sql(
    name="mcc_codes",
    con=engine,
    schema="staging",
    if_exists="append",
    index=False
)

fraud_labels.to_sql(
    name="fraud_labels",
    con=engine,
    schema="staging",
    if_exists="append",
    index=False
)

transactions.to_sql(
    name="transactions",
    con=engine,
    schema="staging",
    if_exists="append",
    index=False,
    chunksize=100_000
)

reload_end = time.perf_counter()
reload_duration = reload_end - reload_start


# --- Validate Load ---

with engine.connect() as connection:
    users_rows = connection.execute(
        text("SELECT COUNT(*) FROM staging.users;")
    ).scalar()

    cards_rows = connection.execute(
        text("SELECT COUNT(*) FROM staging.cards;")
    ).scalar()

    transactions_rows = connection.execute(
        text("SELECT COUNT(*) FROM staging.transactions;")
    ).scalar()

    mcc_codes_rows = connection.execute(
        text("SELECT COUNT(*) FROM staging.mcc_codes;")
    ).scalar()

    fraud_labels_rows = connection.execute(
        text("SELECT COUNT(*) FROM staging.fraud_labels;")
    ).scalar()


print("\n--- Load Validation ---")

print(
    f"staging.users: "
    f"{users_rows:,} / {len(users):,}"
)

print(
    f"staging.cards: "
    f"{cards_rows:,} / {len(cards):,}"
)

print(
    f"staging.transactions: "
    f"{transactions_rows:,} / {len(transactions):,}"
)

print(
    f"staging.mcc_codes: "
    f"{mcc_codes_rows:,} / {len(mcc_codes):,}"
)

print(
    f"staging.fraud_labels: "
    f"{fraud_labels_rows:,} / {len(fraud_labels):,}"
)


# --- Reload Performance ---

print(
    f"\nFull staging reload completed in "
    f"{reload_duration:.2f} seconds."
)