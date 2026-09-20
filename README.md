# FinSight — Fintech Analytics

FinSight is an end-to-end fintech data analytics and machine learning project built around a large financial transaction dataset.

The project combines Python, PostgreSQL, SQL analytics, customer segmentation, retention analysis, feature engineering, and fraud detection modeling. Its goal is to build a reproducible workflow that transforms raw transactional data into validated datasets, database-backed analytics, business insights, and machine learning models.

## Tech Stack

- Python
- PostgreSQL
- SQL
- Pandas
- NumPy
- SQLAlchemy
- scikit-learn
- JupyterLab
- Matplotlib
- PyArrow

## Dataset

This project uses the **Financial Transactions Dataset: Analytics**, originally created by CaixaBank Tech for the 2024 AI Hackathon and distributed via Kaggle.

The dataset contains five source files:

- `transactions_data.csv` — transaction-level data
- `users_data.csv` — customer information
- `cards_data.csv` — payment card information
- `mcc_codes.json` — Merchant Category Code descriptions
- `train_fraud_labels.json` — fraud labels for transactions

The raw dataset is not included in this repository due to its size. It can be downloaded from the [Kaggle dataset page](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data).

## Project Workflow

```text
Raw transactional data
        ↓
Data validation & preprocessing
        ↓
Parquet datasets
        ↓
PostgreSQL staging layer
        ↓
Analytics layer
        ↓
SQL analytics & feature engineering
        ↓
Business insights
        ↓
Fraud detection modeling
```

## Data Pipeline

The project processes approximately **22.2 million records** across transaction, customer, card, merchant category, and fraud-label datasets.

Data is validated and transformed in Python before being loaded into PostgreSQL. The current baseline staging load uses Pandas `to_sql()` with SQLAlchemy and processes the full dataset in approximately **10 minutes**.

Reusable Python functionality is organized as an installable `finsight` package under `src/`.

Raw and processed datasets are intentionally excluded from the repository.

## Analytics

The SQL analytics layer includes:

- KPI and transaction trend analysis
- Merchant category analysis
- Customer 360
- RFM customer segmentation
- Cohort and retention analysis
- Fraud-oriented feature engineering

Selected findings include:

- Monthly active users increased by approximately **11.1%** across the analyzed period.
- Transaction frequency per active user increased by approximately **4.4%**.
- An apparent recurring February decline in transaction value largely disappeared after normalizing values by the number of days in each month.
- Fraud represents approximately **0.15% of labeled transactions**, while fraudulent transactions have substantially higher transaction values across the distribution.
- Merchant categories differ significantly in both fraud rate and absolute fraud volume.
- RFM and retention results reveal important limitations caused by the structure of the observation period, demonstrating the need to distinguish observed activity from true customer acquisition and retention.

Detailed interpretations are available in [`docs/business_insights.md`](docs/business_insights.md).

## Fraud Detection

The fraud detection module uses historical transaction features created in PostgreSQL and a time-based train-validation split to reduce the risk of temporal data leakage.

The current workflow includes:

- fraud distribution analysis over time,
- historical customer- and card-level feature engineering,
- time-based training and validation datasets,
- categorical feature encoding,
- missing-value handling,
- feature scaling,
- Logistic Regression baseline modeling,
- evaluation using recall, precision and F1-score,
- predicted probability analysis,
- classification threshold analysis.

Initial experiments demonstrate why accuracy alone is misleading for highly imbalanced fraud detection data. Lowering the classification threshold substantially improves recall, but produces very low precision, indicating that threshold adjustment alone is not sufficient.

The next stage focuses on comparing the Logistic Regression baseline with alternative classification models using the same validation data and evaluation metrics.

## Repository Structure

```text
finsight-fintech-analytics/
├── data/
│   ├── raw/
│   └── processed/
│
├── dashboard/
│
├── docs/
│   ├── business_insights.md
│   └── load_performance.md
│
├── notebooks/
│   ├── 01_data_overview.ipynb
│   ├── 02_data_quality.ipynb
│   ├── 05_retention_heatmap.ipynb
│   └── ml/
│       ├── 01_fraud_data_preparation.ipynb
│       ├── 02_logistic_regression.ipynb
│       └── 03_model_comparison.ipynb
│
├── sql/
│   ├── analysis/
│   │   ├── 01_kpi_analysis.sql
│   │   ├── 02_merchant_analysis.sql
│   │   ├── 03_customer_360.sql
│   │   ├── 04_rfm_segmentation.sql
│   │   ├── 05_retention_analysis.sql
│   │   └── 06_fraud_ml_features.sql
│   │
│   ├── scripts/
│   │   ├── 01_create_database.sql
│   │   ├── 02_schema.sql
│   │   ├── 03_load_analytics.sql
│   │   └── 04_indexes.sql
│   │
│   └── tests/
│       ├── 01_schema_tests.sql
│       ├── 02_analytics_tests.sql
│       └── 03_index_performance_tests.sql
│
├── src/
│   └── finsight/
│       ├── __init__.py
│       ├── database.py
│       ├── fraud_data.py
│       ├── load_to_postgres.py
│       └── validation.py
│
├── .env.example
├── pyproject.toml
├── requirements.txt
└── README.md
```

## Database

The PostgreSQL database separates raw staging data from analytics-ready structures.

The SQL layer covers:

- database and schema creation,
- analytical table loading,
- indexing,
- KPI and customer analytics,
- retention analysis,
- fraud feature engineering,
- schema and analytics validation,
- index performance testing.

Fraud labels are treated carefully because they are available only for a subset of transactions. Missing fraud labels are therefore not automatically interpreted as legitimate transactions.

## Setup

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Install the local project package in editable mode:

```bash
python3 -m pip install -e .
```

Create a local `.env` file based on:

```text
.env.example
```

Database credentials are stored locally and are not committed to the repository.

## Project Status

**In development**

Completed:

- Data exploration and quality analysis
- Python validation and preprocessing
- PostgreSQL data pipeline
- SQL analytics layer
- KPI and merchant analysis
- Customer 360
- RFM segmentation
- Retention analysis
- Fraud feature engineering
- Time-based ML dataset preparation
- Logistic Regression baseline
- Probability and classification threshold analysis

In progress:

- Fraud model comparison

Planned:

- Final fraud model evaluation and interpretation
- Analytical dashboard
- PostgreSQL bulk-loading optimization
