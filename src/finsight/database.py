import os

from dotenv import load_dotenv
from sqlalchemy import create_engine


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