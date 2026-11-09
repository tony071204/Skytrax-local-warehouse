# airlines

Notebook: `notebook/eda_airlines.ipynb`. Staging model: `stg__airlines`.

## Context

* Lookup table: one row per airline, with only `airline_id` and `airline_name`.
* 595 rows. `airline_id` runs from 1 to 595 with no gap, no duplicate and no null. No duplicate names, even ignoring case.
* Every `airline_id` used in the airline, lounge and seat reviews exists here (0 orphans), and every airline has at least one review.

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| One row is not an airline | Airline 419 is named `Read more` (scraping leftover) and holds 7,292 reviews (6,724 airline, 235 lounge, 333 seat); 6,723 of the 6,724 airline reviews repeat text posted under another airline | Drop the row and its reviews. Review 26647 is a real United review, so it moves to airline 547 |
| No attributes to compare airlines | The table has only an id and a name | Add a seed with service model, region and peer group (not built yet) |

## Key findings

* After the fix 594 airlines remain and `airline_id` is a clean primary key (`unique`, `not_null`).
* 579 of them have airline reviews. The 184 airlines with 100 or more airline reviews hold 94% of those reviews.
* Without a peer group, scores cannot be compared fairly. Scores differ strongly by region and cabin.
