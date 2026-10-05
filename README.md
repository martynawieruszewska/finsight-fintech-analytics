# FinSight - Fintech Analytics & Fraud Detection

End-to-end analytics and machine learning project on **13.3 million card transactions**: from raw data validation, through a PostgreSQL dimensional model and SQL analytics, to fraud detection models evaluated with time-aware validation.

**Highlights**

- Data pipeline: Python validation → Parquet → PostgreSQL staging → star-schema analytics layer (~22.2M records).
- SQL analytics: KPIs, merchant analysis, Customer 360, RFM segmentation and cohort retention.
- Fraud detection on a highly imbalanced target (**0.15% fraud**) with leakage-safe historical features computed in SQL and a strict time-based split.
- Manual experiments on the 2018 validation set: **Gradient Boosting** (`max_depth=15`) caught **23% of fraud** while flagging only **0.43% of transactions** - over **50× the precision of random flagging**.
- Expanding-window temporal cross-validation (2013-2017) exposed **concept drift**: the arrival of chip transactions in 2015 and a change in fraud patterns in 2017. Under time-aware validation, shallower trees (`max_depth=6`) generalized better than the deep trees favored on 2018.

## Tech Stack

Python (Pandas, NumPy, scikit-learn, SQLAlchemy, Matplotlib, PyArrow) · PostgreSQL · SQL · JupyterLab · pytest

## Dataset

[Financial Transactions Dataset: Analytics](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data) (CaixaBank Tech, 2024 AI Hackathon, via Kaggle). The data is synthetic and covers 2010-2019.

| File | Content | Rows |
|---|---|---|
| `transactions_data.csv` | card transactions | 13,305,915 |
| `users_data.csv` | customers | 2,000 |
| `cards_data.csv` | payment cards | 6,146 |
| `mcc_codes.json` | merchant category codes | 109 |
| `train_fraud_labels.json` | fraud labels (67% of transactions) | 8,914,963 |

Raw and processed data are not included in the repository due to their size. Card numbers and CVV codes are removed before the data is saved to Parquet.

## Project Workflow

```text
Raw CSV / JSON
   ↓  validation, type conversion, removal of card numbers and CVV   (notebooks 01-02)
Parquet
   ↓  load into PostgreSQL staging                                   (load_to_postgres.py)
Star schema: fact_transactions + dim_users, dim_cards, dim_mcc, dim_date
   ↓
SQL analytics  ──→  business insights                                (sql/analysis, docs/)
   ↓
ML feature view (window functions, history before each transaction)  (sql/scripts/05)
   ↓
Fraud detection models and temporal validation                       (notebooks/ml)
```

## Key Results

### Business analytics

- Monthly active users grew by ~11% and transactions per active user by ~4.4% over the period.
- The apparent February drop in transaction value disappears after normalizing by the number of days in the month.
- Fraudulent transactions are substantially larger across the whole distribution (median 74.00 vs 31.89).
- Fraud rate and fraud volume rank merchant categories differently (highest rate: Passenger Railways 1.45%; highest volume: Department Stores, 2,251 cases).
- RFM and retention results are driven by the structure of the observation period (most customers are already active at the start), which is documented as a limitation rather than interpreted as exceptional loyalty.

Details: [`docs/business_insights.md`](docs/business_insights.md)

### Fraud detection - exploratory experiments on 2018

Models are trained on transactions before 2018 (all fraud cases plus a deterministic sample of 300,000 legitimate transactions) and evaluated on all 934,599 labeled transactions from 2018 (1,629 fraud cases, 0.17%).

| Model | Recall | Precision | F1 |
|---|---|---|---|
| Logistic Regression (scaled) | 0.009 | 0.010 | 0.010 |
| Random Forest | 0.042 | 0.072 | 0.053 |
| Random Forest + categorical MCC | 0.056 | 0.111 | 0.074 |
| Random Forest + categorical MCC + behavioral features | 0.041 | 0.093 | 0.056 |
| Gradient Boosting (`max_depth=3`, default) | 0.035 | 0.040 | 0.037 |
| Gradient Boosting (`max_depth=6`) | 0.099 | 0.096 | 0.098 |
| Gradient Boosting (`max_depth=10`) | 0.165 | 0.106 | 0.129 |
| Gradient Boosting (`max_depth=15`) | 0.230 | 0.094 | 0.133 |

A random classifier would reach a precision equal to the fraud rate (0.17%). The strongest configuration in these experiments flags 3,991 transactions (0.43% of all), of which 375 are fraudulent.

These were exploratory comparisons. Because 2018 was used repeatedly for model decisions, hyperparameter selection was moved to temporal cross-validation within 2010-2017 (see below).

Selected findings:

- Accuracy is uninformative (above 99.4% for every model, including ones that detect almost no fraud), so models are compared on recall, precision and F1.
- Lowering the Logistic Regression threshold to 0.01 raises recall to 31% only at a precision of 0.27% - threshold tuning alone cannot compensate for a weak model.
- Encoding MCC as a categorical feature improved all metrics; removing `merchant_id` kept recall unchanged but increased false positives.
- Behavioral features (24h activity, time since previous transaction) received high feature importance yet **reduced** validation performance - importance does not imply better generalization.
- For Gradient Boosting, tree depth mattered far more than `learning_rate` or `n_estimators`; the gain from `max_depth=10` to `15` was small (F1 0.129 vs 0.133).

### Temporal validation and concept drift

Expanding-window cross-validation within the development period: each fold trains on all previous years and validates on the next one (2010-2012 → 2013, …, 2010-2016 → 2017). Training folds use the undersampled data, while **each validation fold contains all labeled transactions of its year**, so it is evaluated at the natural fraud rate. On the undersampled data the fraud share of a validation year would be heavily inflated (e.g. 5.35% instead of 0.24% in 2015), overstating precision and F1.

Gradient Boosting (`max_depth=6`) per validation year:

| Year | Fraud rate | Precision | Recall | F1 | False positives |
|---|---|---|---|---|---|
| 2013 | 0.15% | 0.433 | 0.649 | 0.519 | 1,138 |
| 2014 | 0.07% | 0.247 | 0.761 | 0.373 | 1,536 |
| 2015 | 0.24% | 0.030 | 0.734 | 0.059 | 51,090 |
| 2016 | 0.26% | 0.532 | 0.757 | 0.625 | 1,632 |
| 2017 | 0.02% | 0.002 | 0.029 | 0.005 | 2,011 |

Two different failure modes:

- **2015 - new transaction channel (false positives).** Chip transactions were absent until 2014 and made up 71% of legitimate transactions in 2015. The model flagged 5.66% of all transactions (actual fraud rate 0.24%); 98% of the false positives were chip transactions. Performance recovered in 2016, once 2015 was part of the training data.
- **2017 - new fraud patterns (false negatives).** 99% of 2017 fraud used chip transactions, with amounts resembling legitimate chip transactions (median 28.44 vs 76.17 for historical chip fraud). MCC 10 accounted for 19% of chip fraud in 2017 but never appeared in historical chip fraud, and none of its 34 cases were detected. Most missed frauds occurred at merchants already present in the training data, so the failure is not explained by unseen merchants. Only 5 of 172 frauds were detected.

**Time-aware validation changed model selection.** `max_depth=6` achieved the best mean F1 (0.316, vs 0.258 for both `max_depth=2` and `10`) and beat `max_depth=10` in 4 of 5 years, while the manual experiments on 2018 favored deeper trees. Mean F1 is reported together with per-year results, since it is dominated by the drift years.

## Methodology Notes

- **Chronological split.** 2010-2017: development and temporal cross-validation; 2018: validation and model comparison; 2019: untouched final out-of-time test.
- **No temporal leakage in features.** Historical customer and card features use only transactions before the current one (window frames ending at `1 preceding`); same-minute transactions are excluded from 24-hour aggregates.
- **Unlabeled transactions** (33%) are used to build transaction history but excluded from training and evaluation; missing labels are never treated as legitimate.
- **Preprocessing fitted on training data only** (one-hot encoder, median imputation), separately in every cross-validation fold.
- **Reproducibility.** Data loaders use deterministic sampling and ordering, the feature set is defined explicitly in code, and all notebooks run top-to-bottom; re-running the temporal validation notebook reproduces identical results.
- **Sample size caveat.** With 1,629 fraud cases in 2018, a difference of 0.01 in recall corresponds to about 16 transactions; 2017 contains only 172 fraud cases.

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
│       └── 06_temporal_validation.ipynb   # temporal CV and drift diagnostics
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
├── tests/                     # pytest unit tests for src/finsight
├── .env.example
├── LICENSE
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

**2. Data** - download the Kaggle dataset into `data/raw/`.

**3. Validation and Parquet export** - run `notebooks/01_data_overview.ipynb` and `notebooks/02_data_quality.ipynb`.

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

**6. Notebooks** - `notebooks/03_retention_heatmap.ipynb`, then `notebooks/ml/01` to `06` in order.

**7. Tests** - run `pytest` to execute unit tests for data validation, data loading helpers and leakage-safe preprocessing.

## Limitations

- The dataset is synthetic, and yearly fraud prevalence varies strongly (from 0.02% in 2017 to 0.26% in 2016 within the cross-validation years), which makes per-year metrics noisy.
- All reported metrics use the default 0.5 decision threshold. Models are trained on undersampled data, so their predicted probabilities are not calibrated to the natural fraud rate; threshold-independent evaluation is not yet included.
- Most customers are already active at the start of the data, so the first observed transaction is not a true acquisition date - retention and RFM results are descriptive only.
- Absolute fraud detection performance remains modest, and the 2018 validation set was used for several manual model comparisons.

## Next Steps

- Threshold-independent evaluation (average precision) on the temporal folds, to separate ranking failures from threshold effects in 2015 and 2017.
- Systematic hyperparameter tuning on the temporal folds.
- Final model selection based on temporal cross-validation, followed by a single evaluation on 2018 and the untouched 2019 period.
- Decision threshold selection for the final model.
- PostgreSQL bulk loading with `COPY` (current baseline: [`docs/load_performance.md`](docs/load_performance.md)).
