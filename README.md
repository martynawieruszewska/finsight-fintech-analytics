# FinSight - Fintech Analytics & Fraud Detection

End-to-end analytics and machine learning project on **13.3 million card transactions**: from raw data validation, through a PostgreSQL dimensional model and SQL analytics, to fraud detection models evaluated with time-aware validation.

**Highlights**

- Data pipeline: Python validation → Parquet → PostgreSQL staging → star-schema analytics layer (~22.2M records).
- SQL analytics: KPIs, merchant analysis, Customer 360, RFM segmentation and cohort retention.
- Fraud detection on a highly imbalanced target (**0.15% fraud**) with leakage-safe historical features and a strict time-based split.
- Best model on the 2018 validation set: **Gradient Boosting**, catching **23% of fraud** while flagging only **0.43% of transactions** - over **50× the precision of random flagging**.
- Temporal cross-validation exposed **concept drift** (the 2015 shift to chip transactions and a change in fraud patterns in 2017) and showed that evaluating folds on undersampled data overstated F1-scores by up to an order of magnitude.

## Tech Stack

Python (Pandas, NumPy, scikit-learn, SQLAlchemy, Matplotlib, PyArrow) · PostgreSQL · SQL · JupyterLab

## Dataset

[Financial Transactions Dataset: Analytics](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data) (CaixaBank Tech, 2024 AI Hackathon, via Kaggle). The data is synthetic and covers 2010–2019.

| File | Content | Rows |
|---|---|---|
| `transactions_data.csv` | card transactions | 13,305,915 |
| `users_data.csv` | customers | 2,000 |
| `cards_data.csv` | payment cards | 6,146 |
| `mcc_codes.json` | merchant category codes | 109 |
| `train_fraud_labels.json` | fraud labels (67% of transactions) | 8,914,963 |

Raw and processed data are not included in the repository due to their size.

## Project Workflow

```text
Raw CSV / JSON
   ↓  validation, type conversion, removal of card numbers and CVV   (notebooks 01–02)
Parquet
   ↓  load into PostgreSQL staging                                   (load_to_postgres.py)
Star schema: fact_transactions + dim_users, dim_cards, dim_mcc, dim_date
   ↓
SQL analytics & feature views  ──→  business insights               (sql/analysis, docs/)
   ↓
Fraud detection models                                               (notebooks/ml)
```

## Key Results

### Business analytics

- Monthly active users grew by ~11% and transactions per active user by ~4.4% over the period.
- The apparent February drop in transaction value disappears after normalizing by the number of days in the month.
- Fraudulent transactions are substantially larger across the whole distribution (median 74.00 vs 31.89).
- Fraud rate and fraud volume rank merchant categories differently (highest rate: Passenger Railways 1.45%; highest volume: Department Stores, 2,251 cases).
- RFM and retention results are driven by the structure of the observation period (most customers are already active at the start), which is documented as a limitation rather than interpreted as exceptional loyalty.

Details: [`docs/business_insights.md`](docs/business_insights.md)

### Fraud detection — 2018 validation set

Models are trained on transactions before 2018 (all fraud cases plus a deterministic sample of 300,000 legitimate transactions) and evaluated on all 934,599 labeled transactions from 2018 (1,629 fraud cases, 0.17%).

| Model | Recall | Precision | F1 |
|---|---|---|---|
| Logistic Regression (scaled) | 0.009 | 0.010 | 0.010 |
| Random Forest | 0.042 | 0.072 | 0.053 |
| Random Forest + categorical MCC | 0.056 | 0.111 | 0.074 |
| Random Forest + categorical MCC + behavioral features | 0.041 | 0.093 | 0.056 |
| Gradient Boosting (`max_depth=3`, default) | 0.035 | 0.040 | 0.037 |
| Gradient Boosting (`max_depth=6`) | 0.099 | 0.096 | 0.098 |
| **Gradient Boosting (`max_depth=15`)** | **0.230** | **0.094** | **0.133** |

A random classifier would reach a precision equal to the fraud rate (0.17%). The best model flags 3,991 transactions (0.43% of all), of which 375 are fraudulent.

Selected findings:

- Accuracy is uninformative (above 99.4% for every model, including ones that detect almost no fraud), so models are compared on recall, precision and F1.
- Lowering the Logistic Regression threshold raises recall to 31% only at precision below 0.3% — threshold tuning alone cannot compensate for a weak model.
- Encoding MCC as a categorical feature improved all metrics; removing `merchant_id` kept recall unchanged but increased false positives.
- Behavioral features (24h activity, time since previous transaction) received high feature importance yet **reduced** validation performance — importance does not imply better generalization.

### Temporal validation and drift

Expanding-window cross-validation over 2013–2017 (train on all previous years, validate on the next one) revealed:

- **Evaluation must use the natural fraud rate.** Validation folds built from the undersampled data showed F1 of up to 0.85. On complete yearly data, F1 ranged from 0.005 to 0.625.
- **2015 — new transaction channel.** Chip transactions were absent until 2014 and made up 71% of legitimate transactions in 2015. The model flagged 5.66% of all transactions (actual fraud rate 0.24%), producing 51,090 false positives, 98% of them chip transactions.
- **2017 — new fraud patterns.** Fraud amounts resembled legitimate transactions and new merchant categories appeared (e.g. an MCC with no historical chip fraud and 0% recall). Only 5 of 172 frauds were detected.
- **Time-aware validation changed model selection.** `max_depth=6` achieved the best mean F1 (0.316) and beat `max_depth=10` in 4 of 5 years, while manual experiments on 2018 favored deeper trees.

## Methodology Notes

- **No temporal leakage.** Historical customer and card features use only transactions before the current one (window frames ending at `1 preceding`); same-minute transactions are excluded from 24-hour aggregates.
- **Unlabeled transactions** (33%) are used to build transaction history but excluded from training and evaluation; missing labels are never treated as legitimate.
- **Preprocessing fitted on training data only** (one-hot encoder, median imputation).
- **Reproducibility.** Data loaders use deterministic sampling and ordering, the original feature set is defined explicitly in code, and all notebooks run top-to-bottom.
- **Sample size caveat.** With 1,629 fraud cases in 2018, a difference of 0.01 in recall corresponds to about 16 transactions.

## Repository Structure

```text
finsight-fintech-analytics/
├── data/                      # raw/ and processed/ (not tracked)
├── docs/
│   ├── business_insights.md   # interpretation of SQL analytics
│   └── load_performance.md    # PostgreSQL load benchmark
├── notebooks/
│   ├── 01_data_overview.ipynb
│   ├── 02_data_quality.ipynb          # validation, cleaning, Parquet export
│   ├── 03_retention_heatmap.ipynb
│   └── ml/
│       ├── 01_fraud_data_preparation.ipynb
│       ├── 02_logistic_regression.ipynb
│       ├── 03_random_forest.ipynb
│       ├── 04_behavioral_feature_engineering.ipynb
│       ├── 05_gradient_boosting.ipynb
│       └── 06_temporal_validation.ipynb
├── sql/
│   ├── scripts/               # database build pipeline (run in order)
│   ├── analysis/              # analytical queries and views
│   └── tests/                 # schema, data and index checks
├── src/finsight/              # reusable package
│   ├── database.py            # PostgreSQL connection
│   ├── load_to_postgres.py    # staging load
│   ├── validation.py          # data quality checks
│   ├── fraud_data.py          # ML data loading and sampling
│   ├── fraud_preprocessing.py # encoding and missing values
│   └── model_evaluation.py    # evaluation helpers
├── .env.example
└── pyproject.toml
```

## Reproducing the Project

**1. Environment**

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -e ".[dev]"
cp .env.example .env   # fill in PostgreSQL credentials
```

**2. Data** — download the Kaggle dataset into `data/raw/`.

**3. Validation and Parquet export** — run `notebooks/01_data_overview.ipynb` and `notebooks/02_data_quality.ipynb`.

**4. Database**

```text
sql/scripts/01_create_database.sql      (connected to the default postgres database)
sql/scripts/02_schema.sql
python -m finsight.load_to_postgres     (staging load, ~10 min)
sql/scripts/03_load_analytics.sql
sql/scripts/04_indexes.sql
sql/scripts/05_fraud_ml_features.sql
```

**5. Analytics views** - `sql/analysis/03_customer_360.sql`, `04_rfm_segmentation.sql` and `05_retention_analysis.sql` create the views used by the analysis and the retention notebook. Data checks are available in `sql/tests/`.

**6. Notebooks** — `notebooks/03_retention_heatmap.ipynb`, then `notebooks/ml/01` to `06` in order.

**7. Tests** — run `pytest` to execute unit tests for the `finsight` package.

## Limitations

- The dataset is synthetic; fraud labels contain long gaps (39 months with no labeled fraud), so yearly fraud rates vary strongly.
- Most customers are already active at the start of the data, so the first observed transaction is not a true acquisition date - retention and RFM results are descriptive only.
- Absolute fraud detection performance remains modest, and the 2018 validation set was used for several manual model comparisons.

## Next Steps

- Systematic hyperparameter tuning on the temporal folds.
- Final model selection based on temporal cross-validation, followed by a single evaluation on 2018 and the untouched 2019 period.
- Decision threshold selection for the final model.
- PostgreSQL bulk loading with `COPY` (current baseline: [`docs/load_performance.md`](docs/load_performance.md)).