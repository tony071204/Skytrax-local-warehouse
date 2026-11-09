# seat_reviews

Notebook: `notebook/eda_seat_reviews.ipynb`. Staging model: `stg__seat_reviews`.

## Context

* One row is one seat review: 3,766 raw rows, 3,430 after staging, posted May 2007 to Jun 2026. The smallest review table.
* 204 airlines have seat reviews. 24.6% of reviews are verified.
* 7 core ratings from 1 to 5: `seat_legroom`, `seat_recline`, `seat_width`, `aisle_space`, `seat_storage`, `power_supply`, `viewing_tv_screen`.
* 5 lie-flat ratings: `sleep_comfort`, `sitting_comfort`, `seat_bed_width`, `seat_bed_length`, `seat_privacy`.
* Also: cabin, aircraft type, `seat_layout` (for example `3x3x3`).
* Cabins (staged): Economy 2,734, Premium Economy 491, Business 188, First 10, World Traveller Plus 4.

## Problems and decisions

| Problem | Evidence | Decision |
|---|---|---|
| Rows under the fake airline `Read more` | 333 rows (airline 419) | Drop |
| Duplicate reviews | 3 more | Keep the lowest `review_id` |
| Placeholder date | 6 rows with `date_submitted` = 1970-01-01 | Set to null |
| `seat_layout` format | 78 distinct raw values (`3X3`, `2-4-2`, free text such as `Aisle`) | Normalise to `NxN(xN)`, null the rest (19 distinct after) |
| `nationality` | 6 rows not in the country seed | Set to null |
| `customer_name` ends with a number | 3,635 rows | Strip it |
| Real gaps, not errors | The 5 lie-flat ratings are 94.2% to 94.3% null (rated by 198 reviews only); `power_supply` 63.5%, `seat_storage` 34.7%, `viewing_tv_screen` 26.9% | Do not fill |

## Key findings

1. **Recommend rate:** 44.0% overall. By cabin: Premium Economy 52.3%, Economy 42.7%, Business 40.4% (188 reviews). First (10) and World Traveller Plus (4) are too small to read.
2. **Every core seat aspect is weak:** mean rating `seat_recline` 2.65, `seat_width` 2.74, `seat_storage` 2.79, `aisle_space` 2.81, `seat_legroom` 2.84. Nothing stands out. `power_supply` (3.53) and `viewing_tv_screen` (3.10) score higher but are often empty.
3. **What goes with a recommendation** (Spearman, core aspects): `seat_width` 0.69, `seat_legroom` 0.69, `aisle_space` 0.67, `seat_recline` 0.64, `seat_storage` 0.63, `viewing_tv_screen` 0.56, `power_supply` 0.56.
4. **Lie-flat ratings go with a recommendation more strongly** (`sleep_comfort` 0.85, `sitting_comfort` 0.81, `seat_bed_width` 0.81, `seat_bed_length` 0.73) but only about 198 reviews have them, so treat them as a separate premium-cabin view.
5. **Peer comparison is thin:** only 12 of 204 airlines have 100 or more seat reviews and they hold 45% of the reviews; 24 have 30 or more.
6. **The `recommended` flag exists from 2007** (no empty early period), but the yearly rate moves between 21.7% and 63.6% on small counts (for example 23 reviews in 2012), so read yearly rates with care.
