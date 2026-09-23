# FinSight - Fintech Analytics

FinSight is an end-to-end fintech data analytics and machine learning project built around a large financial transaction dataset.

The project combines Python, PostgreSQL, SQL analytics, customer segmentation, retention analysis, feature engineering, and fraud detection modeling. Its goal is to build a reproducible workflow that transforms raw transactional data into validated datasets, database-backed analytics, business insights, and machine learning experiments.

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

Data is validated and transformed in Python before being loaded into PostgreSQL. A baseline staging load using Pandas `to_sql()` with SQLAlchemy processed the full dataset in approximately **10 minutes**.

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

Historical features are calculated using only information available before each transaction. Transactions without known fraud labels can contribute to historical behavior, but are excluded from supervised model training and evaluation.

The current workflow includes:

- fraud target and label coverage analysis,
- historical customer- and card-level feature engineering,
- recent transaction activity and transaction timing features,
- time-based training and validation datasets,
- deterministic training-set undersampling,
- categorical feature encoding,
- semantic missing-value handling,
- feature scaling where required,
- Logistic Regression baseline modeling,
- Random Forest experiments,
- decision-threshold analysis,
- model comparison using recall, precision and F1-score,
- feature importance analysis.

### Logistic Regression

Logistic Regression was used as the initial classification baseline.

Because fraud represents only a very small fraction of labeled transactions, accuracy was found to be misleading as the primary evaluation metric. Decision-threshold experiments showed that lowering the classification threshold can increase recall, but at the cost of extremely low precision.

This demonstrated that threshold adjustment alone was insufficient to produce a useful fraud detection model.

### Random Forest

Random Forest was evaluated as a nonlinear alternative to Logistic Regression.

Experiments included:

- baseline Random Forest,
- limiting tree depth,
- class weighting,
- feature importance analysis,
- categorical representation of Merchant Category Code (`mcc_key`),
- removal of the high-cardinality `merchant_id` feature.

Treating `mcc_key` as a categorical feature instead of an ordered numerical identifier improved recall, precision and F1-score without changing the underlying model.

Removing `merchant_id` reduced performance, indicating that the feature contains useful predictive information despite its high cardinality.

The Random Forest using categorical MCC representation remains the strongest model evaluated so far.

### Behavioral Feature Engineering

Additional behavioral features were engineered in PostgreSQL to investigate whether recent transaction activity improves fraud detection.

The extended feature set includes:

- number of user transactions during the previous 24 hours,
- total user transaction amount during the previous 24 hours,
- time since the user's previous transaction,
- time since the card's previous transaction.

Missing values were handled according to their semantic meaning rather than using a single imputation strategy for all features. Additional binary indicators preserve information about whether previous user or card transaction history exists.

Several behavioral features received relatively high Random Forest feature importance. In particular, recent transaction amount and time since the previous card transaction were among the model's most important features.

However, the extended feature set reduced recall, precision and F1-score on the unchanged time-based validation set.

This demonstrates that high feature importance does not necessarily imply improved model generalization. Further expansion with similar behavioral features is therefore not pursued.

## Repository Structure

```text
finsight-fintech-analytics/
├── data/
│   ├── raw/
│   └── processed/
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
│       ├── 03_random_forest.ipynb
│       └── 04_behavioral_feature_engineering.ipynb
│
├── sql/
│   ├── analysis/
│   │   ├── 01_kpi_analysis.sql
│   │   ├── 02_merchant_analysis.sql
│   │   ├── 03_customer_360.sql
│   │   ├── 04_rfm_segmentation.sql
│   │   └── 05_retention_analysis.sql
│   │
│   ├── scripts/
│   │   ├── 01_create_database.sql
│   │   ├── 02_schema.sql
│   │   ├── 03_load_analytics.sql
│   │   ├── 04_indexes.sql
│   │   └── 06_fraud_ml_features.sql
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
│       ├── fraud_preprocessing.py
│       ├── load_to_postgres.py
│       └── validation.py
│
├── .env.example
├── pyproject.toml
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

Fraud labels are available only for a subset of transactions. Missing fraud labels are therefore not interpreted as legitimate transactions.

For machine learning, historical features are calculated before filtering observations by label availability. This allows previous observed transactions to contribute to transaction history without incorrectly assigning fraud labels to unlabeled records.

## Reproducible ML Experiments

The project separates the original ML feature set from later behavioral features.

The original feature set is explicitly defined in Python so that earlier Logistic Regression and Random Forest experiments remain reproducible even when new features are added to the PostgreSQL feature view.

New feature groups are introduced explicitly for individual experiments rather than automatically changing the input data used by previous models.

Training and validation data are separated chronologically:

- transactions before 2018 are used for training,
- transactions from 2018 are used for validation.

The training set uses deterministic undersampling of non-fraud transactions, while the validation set retains its naturally imbalanced fraud distribution.

## Setup

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install the project and development dependencies:

```bash
python3 -m pip install -e ".[dev]"
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
- Fraud-oriented historical feature engineering
- Time-based ML dataset preparation
- Logistic Regression baseline
- Probability and classification threshold analysis
- Random Forest baseline and model experiments
- MCC categorical representation experiment
- Merchant ID removal experiment
- Behavioral feature engineering
- Behavioral feature importance analysis

In progress:

- Fraud model comparison

Planned:

- Additional classification model evaluation
- Final fraud model comparison and interpretation
- Analytical dashboard
- PostgreSQL bulk-loading optimization