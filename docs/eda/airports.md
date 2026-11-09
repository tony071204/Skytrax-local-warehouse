# airports

Notebook: `notebook/eda_airports.ipynb`. Staging model: `stg__airports`.

## Context

* Lookup table: one row per airport, with only `airport_id` and `airport_name`.
* 1,004 rows. `airport_id` runs from 1 to 1,004 with no gap, no duplicate and no null. No duplicate names, even ignoring case.
* Every `airport_id` used in the airport reviews exists here (0 orphans), and every airport has at least one review.

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| One row is not an airport | Airport 757 is named `Read more` (scraping leftover) and holds 558 reviews | Drop the row and its reviews |
| Accents and dash styles vary | 16 names contain non-ASCII characters (accents, en-dash); the dash style is inconsistent | Keep as they are for now: the accents are real spellings, only the dashes vary |
| Short names look wrong | `Goa`, `Kos`, `Leh` | Keep: they are real airports |

## Key findings

* After the fix 1,003 airports remain and `airport_id` is a clean primary key (`unique`, `not_null`).
* The 133 airports with 100 or more reviews hold 74% of the airport reviews. The long tail has few reviews.
* The table has no city, country or IATA code, so location analysis needs another source.
