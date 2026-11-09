# Skytrax EDA: key findings

First read of the data, before any dashboard or deeper analysis. Each table has its own page; this page is the summary.

Numbers come from `database/dev.duckdb` (`raw_*` and `stg__*` tables), checked on 5 Nov 2026. The notebooks in `notebook/` hold the full exploration.

## 1. What the dataset contains

Skytrax is a public review site. The data is four review tables and two small lookup tables.

| Table | One row is | Raw rows | After staging | Reviews posted | Recommend rate |
|---|---|---:|---:|---|---:|
| [airline_reviews](airline_reviews.md) | one flight review | 156,323 | 149,362 | Jan 2002 to Apr 2026 | 38.1% |
| [airport_reviews](airport_reviews.md) | one airport visit | 49,505 | 48,852 | Jul 2002 to Jun 2026 | 23.7% |
| [lounge_reviews](lounge_reviews.md) | one lounge visit | 5,087 | 4,850 | May 2006 to Jun 2026 | 52.0% |
| [seat_reviews](seat_reviews.md) | one seat review | 3,766 | 3,430 | May 2007 to Jun 2026 | 44.0% |
| [airlines](airlines.md) | one airline | 595 | 594 | n/a | n/a |
| [airports](airports.md) | one airport | 1,004 | 1,003 | n/a | n/a |

* `review_id` is unique in every review table. Each review has 1 to 5 ratings per aspect, a yes/no `recommended`, reviewer nationality, traveller type, cabin, dates and free text.
* Reviews are voluntary posts, not a survey. Results describe people who write reviews.

## 2. Problems found and what we decided

| Problem | Evidence | Decision |
|---|---|---|
| A fake entity named `Read more` (scraping leftover) | Airline 419 holds 6,724 airline, 235 lounge and 333 seat reviews. Airport 757 holds 558 reviews. 6,723 of the 6,724 airline reviews repeat text posted under another airline. | Drop both entities and all their reviews. Review 26647 is a real United review, so it moves to airline 547. |
| Duplicate reviews | After the step above, 238 airline, 95 airport, 2 lounge and 3 seat reviews repeat the same entity, reviewer, day and text. | Keep one row (lowest `review_id`). |
| Number glued to `customer_name` (for example `Joshua Torres 6`) | 150,886 airline, 47,722 airport, 4,893 lounge, 3,635 seat rows. | Strip the number. |
| `nationality` is free text | Not a country in the 217-country seed: 614 airline rows (542 distinct values), 1,738 airport rows (1,660 distinct), 1 lounge row, 6 seat rows. | Keep only values found in the seed, set the rest to null. |
| Wrong dates | 6 seat reviews dated 1970-01-01; 41 airline reviews with `date_flown` after `date_submitted`. | Set to null. |
| Messy route columns (airline reviews) | City filled but no airport code: 40,387 origin, 42,571 destination, 8,599 transit rows. A 3-letter code typed in a city column: 4,081, 4,606 and 1,056 rows. | Clean in `stg__airline_locations`: move codes to the airport column, null junk (uses the `iata_airports` seed). Distinct origin cities fall from 3,784 to 2,978. |
| `updated_at` is load time | 61 distinct values in airline reviews, 1 in the other tables. | Drop the column. |

Table-specific problems (`lounge_name`, `seat_layout`) are on their own pages.

## 3. Key findings to keep in mind before analysing

1. **The `recommended` flag was not recorded in the early years.** Recommend rate by review year:

   | Table | Rate before the flag works | First reliable year |
   |---|---|---|
   | airline | 1.1% to 10.6% (2006 to 2008), 37.8% (2009) | 2010 (62.8%) |
   | airport | 0.0% to 0.6% (2005 to 2010), 7.7% (2011) | 2012 (45.5%) |
   | lounge | 0.0% to 11.2% (2006 to 2011) | 2012 (57.3%) |
   | seat | none: the flag exists from the start (2007: 60.0% on 5 reviews) | 2007 |

   Use airline reviews from 2010 and airport and lounge reviews from 2012 for any recommend rate.

2. **The airline recommend rate fell a lot and is only partly back.** 62.8% (2010), 52.5% (2014), 29.5% (2019), 18.0% (2021), 34.5% (2026, only 763 reviews so far). Compare airlines in the same period.

3. **An empty rating is not a low rating.** The review form grew over time: airline reviews fill on average 0.13 ratings in 2008, 3.72 in 2012 and 5.66 in 2016. Never fill nulls with 0.

4. **Reviews are concentrated in few entities.** Entities with at least 100 reviews:

   | Table | Entities with reviews | With 100+ reviews | Share of reviews they hold |
   |---|---:|---:|---:|
   | airline | 579 | 184 | 94% |
   | airport | 1,003 | 133 | 74% |
   | lounge | 158 | 15 | 55% |
   | seat | 204 | 12 | 45% |

   Peer comparison works for airlines and airports, and is thin for lounges and seats.

5. **Cabin changes everything.** Airline recommend rate from 2010: Business 60.9%, First 54.0%, Premium Economy 41.3%, Economy 34.4%. Economy rates all seven aspects lowest. Only compare like with like.

6. **Wifi is the weakest aspect in every cabin** (mean rating, airline reviews from 2010): Economy 1.83, Premium Economy 2.24, First 2.69, Business 2.76. It is also rated by only 25.6% of reviews.

7. **`value_for_money` goes with `recommended` most (Spearman 0.83), but it is an outcome, not a lever.** It correlates 0.64 to 0.79 with every other aspect. Next come `ground_service` 0.77 and `cabin_staff_service` 0.74. These are associations, not causes.

8. **Verified reviews are harsher.** Airline reviews from 2010: 28.6% of verified reviews recommend, against 45.0% of unverified ones. Verified are 39.5% of all airline reviews, so mix matters when comparing periods.

9. **Airport reviews cannot be tied to an airline.** They only know the airport. Lounge and seat reviews do carry an `airline_id`.

## 4. Open items

* `airline_id` has no service model, region or peer group yet. A seed is needed before any peer comparison.
* Cleaning rules are written in `skytrax/models/staging/` and covered by dbt tests.
