# Local Data Warehouse Pipeline

A local-first ELT data warehouse built on Skytrax airline review data. Raw CSVs are ingested into DuckDB (OLAP),
transformed with dbt into analytics-ready models, and served through interactive Streamlit dashboards. Everything runs
on a single laptop with zero cloud dependencies.

## Architecture

```
CSV files (data_gz/)
   |  scripts/ingest_raw.py
   v
DuckDB (database/dev.duckdb)  ->  raw_* tables
   |  dbt
   v
staging  ->  intermediate  ->  marts
   |
   v
Streamlit dashboards
```

## Tech stack

- **DuckDB**: local OLAP database
- **dbt-core + dbt-duckdb**: transformations, tests, docs
- **Python**: ingestion script
- **Streamlit**: interactive dashboards for visualization

## Dataset

Skytrax reviews: `airlines`, `airports`, `airline_reviews`, `airport_reviews`, `lounge_reviews`, `seat_reviews`.

The CSVs are stored gzip-compressed in `data_gz/` to stay under GitHub's file size limit.
