# PostgreSQL Load Performance

## Baseline — Pandas `to_sql()`

- Date: 2026-08-27
- Total rows: ~22.2M
- Method: Pandas `to_sql()` + SQLAlchemy
- Transactions `chunksize`: 100,000
- Full staging reload: 616.52 seconds (~10 min 17 sec)
- Result: all staging row counts matched source Parquet files

This benchmark serves as a baseline for future bulk-loading optimizations, such as PostgreSQL `COPY`.