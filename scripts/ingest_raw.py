"""Ingest the Skytrax raw CSVs into the local DuckDB warehouse.

Reads the CSVs in `data/` and writes each one as a raw_* table
inside `database/dev.duckdb`.

Usage:
    python scripts/ingest_raw.py
"""

from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"
DB_PATH = ROOT / "database" / "dev.duckdb"

CSV_FILES = [
    "airlines.csv",
    "airports.csv",
    "airline_reviews.csv",
    "airport_reviews.csv",
    "lounge_reviews.csv",
    "seat_reviews.csv",
]


def main() -> None:
    con = duckdb.connect(str(DB_PATH))
    try:
        print(f"Ingesting into {DB_PATH.relative_to(ROOT)}")
        for csv in CSV_FILES:
            path = DATA_DIR / csv
            if not path.exists():
                raise FileNotFoundError(f"Missing CSV: {path.relative_to(ROOT)}")
            table = f"raw_{path.stem}"  # airlines.csv -> raw_airlines
            con.execute(
                f"CREATE OR REPLACE TABLE {table} AS "
                f"SELECT * FROM read_csv_auto(?, sample_size=-1)",
                [str(path)],
            )
            n = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            print(f"  {table}: {n} rows")
    finally:
        con.close()
    print("Done.")


if __name__ == "__main__":
    main()