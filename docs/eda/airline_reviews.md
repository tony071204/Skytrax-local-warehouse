# airline_reviews

Notebook: `notebook/eda_airline_reviews.ipynb`. Staging model: `stg__airline_reviews`.

## Context

* One row is one flight review. The largest table: 156,323 raw rows, 149,362 after staging, posted Jan 2002 to Apr 2026.
* 579 airlines have at least one review. 39.5% of reviews are verified.
* 7 ratings from 1 to 5: `seat_comfort`, `cabin_staff_service`, `food_and_beverages`, `inflight_entertainment`, `ground_service`, `wifi_and_connectivity`, `value_for_money`.
* Also: cabin (`seat_type`), traveller type, aircraft, route (origin, destination, transit), `date_flown` (first day of the flight month).

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| Rows under the fake airline `Read more` | 6,724 rows (airline 419), 6,723 of them copies of reviews under other airlines | Drop; review 26647 moves to United (547) |
| Duplicate reviews | 238 more after the step above | Keep the lowest `review_id` |
| Route columns messy | 40,387 origin and 42,571 destination rows have a city but no airport code; 4,081 origin and 4,606 destination cities hold a 3-letter code | Clean in `stg__airline_locations` (see the [summary](README.md)) |
| `date_flown` after `date_submitted` | 41 rows | Set to null |
| `nationality` free text | 614 rows not in the country seed | Set to null |
| `customer_name` ends with a number | 150,886 rows | Strip it |
| Real gaps, not errors | `wifi_and_connectivity` 74.4% null, `aircraft` 73.6%, `inflight_entertainment` 42.2%, `type_of_traveller` 25.5%, `date_flown` 25.6% (staged) | Do not fill |

## Key findings

Rating figures use reviews posted from 2010 (the year the `recommended` flag starts to work).

1. **Recommend rate by cabin:** Business 60.9%, First 54.0%, Premium Economy 41.3%, Economy 34.4%. Economy is 81% of the reviews (119,198 of 147,515 posted from 2010).
2. **Lowest mean rating:** `wifi_and_connectivity` 1.99, then `ground_service` 2.39 and `value_for_money` 2.61. Highest: `cabin_staff_service` 2.98.
3. **Mean rating by cabin** (Economy / Premium Economy / Business / First):

   | Aspect | Economy | Premium Economy | Business | First |
   |---|---:|---:|---:|---:|
   | wifi_and_connectivity | 1.83 | 2.24 | 2.76 | 2.69 |
   | ground_service | 2.25 | 2.68 | 3.20 | 3.11 |
   | value_for_money | 2.49 | 2.68 | 3.32 | 3.06 |
   | cabin_staff_service | 2.84 | 3.09 | 3.75 | 3.59 |

4. **What goes with a recommendation** (Spearman with `recommended`): `value_for_money` 0.83, `ground_service` 0.77, `cabin_staff_service` 0.74, `food_and_beverages` 0.72, `seat_comfort` 0.72, `wifi_and_connectivity` 0.63, `inflight_entertainment` 0.63. Association, not cause. `value_for_money` is an outcome of the other aspects (0.64 to 0.79 with each).
5. **No two ratings are duplicates of each other.** None of the aspect pairs reaches 0.8.
6. **Traveller type:** recommend rate Solo Leisure 38.3%, Business 32.0%, Couple Leisure 29.8%, Family Leisure 27.5%. A quarter of the reviews have no traveller type.
7. **Time:** reviews peak in 2019 (15,360) and fall to 5,876 in 2020. The recommend rate drops from 62.8% (2010) to 18.0% (2021), see the [summary](README.md).
8. **Peers:** 184 of 579 airlines have 100 or more reviews and hold 94% of the reviews; 299 have 30 or more.
