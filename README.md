# Skytrax Local Data Warehouse

![Skytrax airline rating](https://s28477.pcdn.co/wp-content/uploads/2025/06/Starlux_5Star_1.jpg)
<sub>Image: Skytrax (skytraxratings.com)</sub>

A local data warehouse built from ~200k airline, airport, lounge and seat reviews from Skytrax. Raw CSVs are loaded into **DuckDB**, cleaned and modelled into **star schemas** with **dbt**, and prepared for analysis. It runs on one laptop, with no cloud account.

**[Interactive ERD](https://tony071204.github.io/Skytrax-local-warehouse/)** | [EDA findings](docs/eda/README.md)

**Contents:** [1. Description](#1-description) | [2. Ingestion](#2-ingestion) | [3. Modelling](#3-modelling) | [4. Analysis](#4-analysis)

---

## 1. Description

### Why this project

Airlines compete on service, and passengers say what they think in public reviews. [Skytrax](https://www.airlinequality.com/) is one of the best-known review sites in the industry. Its data covers ~200k reviews from 2002 to 2026 across airlines, airports, lounges and seats. Each review has ratings for service areas (seat comfort, cabin staff, food, ground service and more), a "would you recommend?" answer, and details about the traveller. That makes it a good base to ask: *how do passengers see us, compared with others, and what should we fix first?*

But the raw data cannot answer that yet. It has duplicates, fake entries, messy text and wrong dates.

So this project plays the role of an **analytics engineer at an airline**:

1. **Build a reliable pipeline.** Load the raw files into a local warehouse and organise them in three layers: **Bronze** (raw, unchanged), **Silver** (cleaned and prepared), **Gold** (star schemas ready for analysis).
2. **Turn the data into insights.** Use the Gold layer to find where the airline falls behind and what to improve first. See [4. Analysis](#4-analysis).

### Architecture

```
        ┌──────────────────────────────────────────────────┐
        │ SOURCE                                           │
        │ 6 CSV files                                      │
        │ airline / airport / lounge / seat reviews,       │
        │ airlines, airports                               │
        └─────────────────────────┬────────────────────────┘
                                  │ python scripts/ingest_raw.py  (load unchanged)
                                  ▼
        ┌──────────────────────────────────────────────────┐
        │ BRONZE  (database/dev.duckdb)                    │
        │ raw_airline_reviews   raw_airport_reviews        │
        │ raw_lounge_reviews    raw_seat_reviews           │
        │ raw_airlines          raw_airports               │
        └─────────────────────────┬────────────────────────┘
                                  │ dbt staging: clean, dedupe, fix text and dates
                                  ▼
        ┌──────────────────────────────────────────────────┐
        │ SILVER  /  stg__*                                │
        │ stg__airline_reviews   stg__airport_reviews      │
        │ stg__lounge_reviews    stg__seat_reviews         │
        │ stg__airlines           stg__airports            │
        └─────────────────────────┬────────────────────────┘
                                  │ dbt intermediate: fill Unknown, cast types
                                  ▼
        ┌──────────────────────────────────────────────────┐
        │ SILVER  /  int__*                                │
        │ int__airline_reviews   int__airport_reviews      │
        │ int__lounge_reviews    int__seat_reviews         │
        └─────────────────────────┬────────────────────────┘
                                  │ dbt marts: build dimensions and facts
                                  ▼
        ┌──────────────────────────────────────────────────┐
        │ GOLD  (star schemas)                             │
        │ fct_airline_reviews   fct_airport_reviews        │
        │ fct_lounge_reviews    fct_seat_reviews           │
        │ dim_date  dim_airline  dim_cabin  dim_country    │
        │ dim_traveller_type  dim_aircraft  dim_airport    │
        │ dim_airport_experience  dim_lounge               │
        └──────────────────────────────────────────────────┘
                                  │
                                  ▼
                         Analysis  (in progress)
```

Everything from Bronze to Gold lives in one DuckDB file, `database/dev.duckdb`.

| Step | Folder | What happens |
|---|---|---|
| Ingestion | `scripts/` | A Python script loads each CSV into DuckDB, unchanged (Bronze). |
| Staging | `skytrax/models/staging/` | Clean each table: remove junk and duplicates, fix text and dates (Silver). |
| Intermediate | `skytrax/models/intermediate/` | Prepare for modelling: fill missing labels, set data types (Silver). |
| Marts | `skytrax/models/marts/` | Build dimensions and facts, the star schema (Gold). |
| Analysis | | Answer business questions from the Gold layer. |

### Tech stack

In the order data moves through the project:

| Step | Technology |
|---|---|
| Ingestion | Python script |
| Storage | DuckDB (local, single file) |
| Transformation, tests | dbt Core + dbt-duckdb |
| Lookup data | dbt seeds |
| ERD | [qdbd](https://qdbd.dev), published with GitHub Pages |

### Quickstart

Requires Python 3.10+.

```bash
# 1. Install
git clone https://github.com/tony071204/Skytrax-local-warehouse.git
cd Skytrax-local-warehouse
python -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 2. Unzip the data (CSVs are stored gzipped to fit GitHub's size limit)
mkdir -p data && gunzip -c data_gz/airlines.csv.gz > data/airlines.csv
# repeat for the other 5 files (airports, airline_reviews, airport_reviews, lounge_reviews, seat_reviews)

# 3. Load raw tables into DuckDB
python scripts/ingest_raw.py

# 4. Build everything with dbt (seeds, models, tests)
cd skytrax
dbt seed
dbt build
```

<!-- TODO: replace step 2 with one command (a small script) so it is not repeated 6 times -->

### Project structure

```
data_gz/            raw CSVs (gzipped)
scripts/            ingest_raw.py: CSV -> DuckDB raw tables
skytrax/
  models/
    staging/        stg__*  cleaning
    intermediate/   int__*  preparation
    marts/          dim_* and fct_*  star schemas
  seeds/            countries, iata_airports, airline_attributes
  macros/           date dimension generator
docs/
  eda/              what we found in the raw data
  erd/              interactive ERD source (published to GitHub Pages)
notebook/           EDA notebooks
tests/              tests for the ingest script
```

---

## 2. Ingestion

`scripts/ingest_raw.py` reads the 6 CSV files and writes each one, unchanged, as a `raw_*` table in `database/dev.duckdb`. No cleaning happens here, so raw always matches the source.

| Raw table | One row is | Rows |
|---|---|---:|
| `raw_airline_reviews` | one flight review | 156k |
| `raw_airport_reviews` | one airport visit | 49.5k |
| `raw_lounge_reviews` | one lounge visit | 5.1k |
| `raw_seat_reviews` | one seat review | 3.8k |
| `raw_airlines` | one airline | 595 |
| `raw_airports` | one airport | 1,004 |

### What we found in the raw data

Before cleaning anything, we explored every table (notebooks in `notebook/`, write-up in [`docs/eda/`](docs/eda/README.md)). The main problems:

- **A fake entity called "Read more"** (a scraping leftover) holds thousands of reviews copied from real airlines.
- **Duplicate reviews**, the same reviewer, day and text posted twice.
- **Messy text**: numbers glued to reviewer names, free-text nationality, city names typed as airport codes.
- **Impossible dates**, for example `1970-01-01`.

Each problem, its evidence and our decision is listed in the [EDA findings](docs/eda/README.md).

---

## 3. Modelling

dbt builds three layers on top of the raw tables. The same flow applies to all four review types:

`raw_airline_reviews` -> `stg__airline_reviews` -> `int__airline_reviews` -> `fct_airline_reviews`

Same process applies to `airport`, `lounge` and `seat`

| Layer | Folder | What it does |
|---|---|---|
| Staging | `skytrax/models/staging/` | One model per raw table. Cleans the data. |
| Intermediate | `skytrax/models/intermediate/` | Prepares each review table for modelling. No rows added or removed. |
| Marts | `skytrax/models/marts/` | Dimensions and facts (star schema). |
| Seeds | `skytrax/seeds/` | Small lookup files kept in the repo. |

### Staging: cleaning rules

- **Drop scraping leftovers.** "Read more" (airline 419, airport 757) is removed. One real United review found under it is moved back.
- **Remove exact duplicates.** Keep one row per same entity + reviewer + day + text.
- **Fix messy text.** Strip numbers from reviewer names, normalise lounge names and seat layouts.
- **Validate with lookup seeds.** Nationality must exist in `countries`. City and airport codes are cleaned with `iata_airports`. Anything else becomes NULL, never guessed.
- **Remove impossible dates.** `1970-01-01` and "flown after submitted" become NULL.

### Intermediate: preparing for the marts

- NULL labels become `Unknown` (cabin, nationality, traveller type), so no review disappears in a join later.
- Ratings are cast to integers (NULL stays NULL, meaning "not rated").
- `recommended` becomes 0/1.

### Marts: star schema

A star schema has **one fact table in the middle** (the measurements) and **dimensions around it** (who, where, when). Here is the simplest case, the airline review fact. Every other fact follows the same pattern.

![Star schema of fct_airline_reviews](docs/images/star_airline.png)



#### Four facts, one shared set of dimensions

| Fact | One row is | ~Rows | Joins to |
|---|---|---:|---|
| `fct_airline_reviews` | one flight review | 149k | date (x2), airline, cabin, traveller type, country |
| `fct_airport_reviews` | one airport visit review | 49k | date (x2), airport, airport experience, traveller type, country |
| `fct_lounge_reviews` | one lounge visit review | 4.9k | date (x2), airline, lounge, traveller type, country |
| `fct_seat_reviews` | one seat review | 3.4k | date (x2), airline, cabin, aircraft, traveller type, country |

Each fact holds the **ratings** (1-5 per aspect, NULL if not rated) and a `recommended` (0/1). Everything else is a key to a dimension.

**Dimensions:** `dim_date`, `dim_airline`, `dim_cabin`, `dim_traveller_type`, `dim_country`, `dim_aircraft`, `dim_airport`, `dim_airport_experience`, `dim_lounge`.

All 13 tables and their columns: **[interactive ERD](https://tony071204.github.io/Skytrax-local-warehouse/)**.

#### Key design decisions

- **Grain = one review per row.** Simple, and every other number (rate, average) is calculated from it at query time.
- **Shared dimensions.** `dim_date`, `dim_airline`, `dim_cabin`, `dim_traveller_type` and `dim_country` are built once and reused, so results from different facts can be compared.
- **Two dates per review.** `date_flown` (or visit date) is the main date. `date_submitted` is secondary. Reviews are written long after the trip, so the two answer different questions.
- **`recommended` stored as 0/1.** The *rate* is computed in the query (`avg(recommended)`), so it works at any level of grouping.
- **Peer groups come from a seed.** `airline_attributes` labels each airline with service model, region and peer group (for example "European full-service"), which enables fair comparisons like British Airways vs. its peers.
- **Airport reviews stand alone.** They cannot be reliably linked to an airline, so `fct_airport_reviews` has no `dim_airline`.

### Output

After `dbt build` you have:

- `database/dev.duckdb`: one file with the `raw_*`, `stg__*`, `int__*` and mart tables
- 9 dimensions and 4 facts, with dbt tests on keys and relationships
- A query you can run right away, the recommend rate by cabin:

```sql
SELECT c.cabin_name,
       count(*)                                AS reviews,
       round(100 * avg(f.recommended), 1) AS recommend_pct
FROM fct_airline_reviews f
JOIN dim_cabin c USING (cabin_key)
GROUP BY 1
ORDER BY reviews DESC;
```

---

## 4. Analysis

In progress.
