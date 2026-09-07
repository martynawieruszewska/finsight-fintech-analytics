# FinSight — Fintech Analytics

FinSight is an end-to-end fintech data analytics project built around a large transactional dataset. The project combines Python, PostgreSQL, SQL analytics, customer segmentation, retention analysis, and an ongoing fraud detection module.

The goal is to build a reproducible analytical workflow that transforms raw financial data into validated datasets, database-backed analytics, and business insights.

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
SQL analysis & feature engineering
        ↓
Business insights
        ↓
Fraud detection [work in progress]
```

## Data Pipeline

The project processes approximately **22.2 million records** across transaction, customer, card, merchant category, and fraud-label datasets.

Data is validated and transformed in Python before being loaded into PostgreSQL. The current baseline staging load uses Pandas `to_sql()` with SQLAlchemy and loads the full dataset in approximately **10 minutes**.

Raw and processed datasets are intentionally excluded from the repository.

## Analytics

The SQL analytics layer currently includes:

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

The fraud detection module is currently under development.

The analytical dataset and historical features have been prepared with particular attention to avoiding data leakage. Initial work includes temporal analysis of fraud labels, time-based dataset splitting, preprocessing, and baseline model evaluation.

More advanced model development will be added as the project progresses.

## Repository Structure

```text
finsight-fintech-analytics/
├── data/
│   ├── raw/
│   └── processed/
├── dashboard/
├── docs/
│   ├── business_insights.md
│   └── load_performance.md
├── notebooks/
│   ├── 01_data_overview.ipynb
│   ├── 02_data_quality.ipynb
│   ├── 05_retention_heatmap.ipynb
│   └── 06_fraud_detection_ml.ipynb
├── sql/
│   ├── analysis/
│   ├── scripts/
│   └── tests/
├── src/
│   ├── load_to_postgres.py
│   └── validation.py
├── .env.example
├── requirements.txt
└── README.md
```

## Database

The PostgreSQL layer separates database setup, analytics queries, and validation tests.

SQL scripts include schema creation, data loading, indexing, analytical transformations, and database tests. Index performance is also evaluated separately.

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

Create a local environment file based on:

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

In progress:

- Fraud detection modeling

Planned:

- Model comparison and interpretation
- Analytical dashboard
- PostgreSQL bulk-loading optimization
