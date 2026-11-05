# lounge_reviews

Notebook: `notebook/eda_lounge_reviews.ipynb`. Staging model: `stg__lounge_reviews`.

## Context

* One row is one lounge visit review: 5,087 raw rows, 4,850 after staging, posted May 2006 to Jun 2026.
* 158 airlines have lounge reviews. 21.4% of reviews are verified.
* 7 ratings from 1 to 5: `comfort`, `cleanliness`, `bar_and_beverages`, `catering`, `washrooms`, `wifi_connectivity`, `staff_service`.
* Also: lounge name, airport, `type_of_lounge`. Lounge types (staged): Business Class 3,466, First Class 488, Frequent Flyer 389, Members 114, Pay to Use 93.

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| Rows under the fake airline `Read more` | 235 rows (airline 419) | Drop |
| Duplicate reviews | 2 more | Keep the lowest `review_id` |
| `lounge_name` missing | 2,411 of 5,087 raw rows (47.4%) | Keep as null, do not guess |
| `lounge_name` format | 19 end with `LOUNGE REVIEW`, 1 is `=`, many spelling variants (1,089 distinct raw) | Upper case, drop the ` REVIEW` ending, `=` to null, merge spellings (983 distinct after) |
| `nationality` | 1 value not in the country seed | Set to null |
| `customer_name` ends with a number | 4,893 rows | Strip it |
| `type_of_traveller` has one value only (`Business`, 3,634 rows; the rest null) | No information | Not carried into staging |

## Key findings

Rating figures use reviews posted from 2012 (4,106 staged reviews), because the `recommended` flag is empty before.

1. **Recommend rate:** 60.5% from 2012 (52.0% over all years). By lounge type: Frequent Flyer 70.3%, Members 70.2%, First Class 62.3%, Business Class 59.3%, Pay to Use 57.0%.
2. **Lowest mean rating:** `catering` 2.91, then `bar_and_beverages` 3.28 and `washrooms` 3.29. Highest: `cleanliness` 3.72 and `wifi_connectivity` 3.70.
3. **No single aspect dominates a recommendation.** Spearman is between 0.55 and 0.68: `comfort` 0.68, `catering` 0.68, `staff_service` 0.67, `bar_and_beverages` 0.64, `cleanliness` 0.64, `washrooms` 0.61, `wifi_connectivity` 0.55. `catering` is the clearer target because it is both strong and lowest rated.
4. **Little room for peer comparison:** only 15 of 158 airlines have 100 or more lounge reviews, and they hold 55% of the reviews; 44 have 30 or more.
5. **Top lounges by reviews:** Admirals Club 95, Maple Leaf 67, United Club 61.
