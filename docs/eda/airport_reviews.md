# airport_reviews

Notebook: `notebook/eda_airport_reviews.ipynb`. Staging model: `stg__airport_reviews`.

## Context

* One row is one airport visit review: 49,505 raw rows, 48,852 after staging, posted Jul 2002 to Jun 2026.
* 1,003 airports have reviews. 21.6% of reviews are verified.
* 8 ratings from 1 to 5: `queuing_times`, `terminal_cleanliness`, `terminal_seating`, `terminal_signs`, `food_beverages`, `airport_shopping`, `airport_staff`, `wifi_connectivity`.
* Also: `experience_at_airport` (departure only, arrival only, arrival and departure, transit), traveller type, `date_visit`.
* These reviews have no airline. They cannot be tied to an airline.

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| Rows under the fake airport `Read more` | 558 rows (airport 757) | Drop |
| Duplicate reviews | 95 more | Keep the lowest `review_id` |
| `nationality` is the most polluted column | 1,845 distinct raw values for about 200 countries; 1,738 rows not in the country seed (for example `Terminal 2`, `45min`) | Set to null |
| `customer_name` ends with a number | 47,722 rows | Strip it |
| Real gaps, not errors | `wifi_connectivity` 56.0% null, `food_beverages` 48.8%, `terminal_seating` 43.2%, `airport_staff` 40.4%, `terminal_signs` 36.1%, `experience_at_airport` 34.8% | Do not fill |

## Key findings

Rating figures use reviews posted from 2012, because the `recommended` flag is empty before.

1. **Recommend rate:** 28.2% from 2012 (23.7% over all years). It falls from 45.5% (2012) to 15.0% (2021) and recovers to 23.9% (2026).
2. **Lowest mean rating:** `airport_staff` 2.19, `queuing_times` 2.34, `food_beverages` 2.37, `terminal_seating` 2.38. Highest: `terminal_cleanliness` 3.00.
3. **What goes with a recommendation** (Spearman): `airport_staff` 0.67, `queuing_times` 0.66, `terminal_seating` 0.60, `terminal_cleanliness` 0.59, `airport_shopping` 0.58, `terminal_signs` 0.58, `food_beverages` 0.56, `wifi_connectivity` 0.50. Staff and queues lead and are also the lowest rated.
4. **Visit type matters:** recommend rate is 32.2% for arrival and departure, 21.9% for transit, 20.2% for arrival only and 20.0% for departure only. Compare airports within the same visit type.
5. **Peers:** 133 of 1,003 airports have 100 or more reviews and hold 74% of the reviews; 282 have 30 or more.
6. **Rating forms changed.** Old reviews have fewer ratings filled, so an empty rating in old years is not a low score.
