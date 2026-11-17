-- fct_airline_reviews
-- Grain   : one row per airline review (review_id)
-- Source  : int__airline_reviews, keys looked up in the dims
-- Dates   : date_flown_key / date_submitted_key both point to dim_date (role-playing);
--           a missing date maps to the Unknown row (date_key = -1)
-- Scores  : kept NULL when the reviewer did not score a category, so avg() ignores them
--           (a recommend rate is avg(recommended); it is not stored here)

select
    r.review_id,

    case when r.date_flown     is null then -1 else flown.date_key     end as date_flown_key,
    case when r.date_submitted is null then -1 else submitted.date_key end as date_submitted_key,
    airline.airline_key,
    cabin.cabin_key,
    traveller.traveller_type_key,
    country.country_key,

    r.verify,

    cast(r.seat_comfort           as double)   as seat_comfort,
    cast(r.cabin_staff_service    as double)   as cabin_staff_service,
    cast(r.food_and_beverages     as double)   as food_and_beverages,
    cast(r.inflight_entertainment as double)   as inflight_entertainment,
    cast(r.ground_service         as double)   as ground_service,
    cast(r.wifi_and_connectivity  as double)   as wifi_and_connectivity,
    cast(r.value_for_money        as double)   as value_for_money,

    cast(r.recommended as smallint)            as recommended,
    cast(1 as smallint)                        as review_count

from {{ ref('int__airline_reviews') }} as r
left join {{ ref('dim_date') }}          as flown     on flown.full_date     = r.date_flown
left join {{ ref('dim_date') }}          as submitted on submitted.full_date = r.date_submitted
left join {{ ref('dim_airline') }}       as airline   on airline.airline_id  = r.airline_id
left join {{ ref('dim_cabin') }}         as cabin     on cabin.cabin_name    = r.cabin_name
left join {{ ref('dim_traveller_type') }} as traveller on traveller.traveller_type = r.traveller_type
left join {{ ref('dim_country') }}       as country   on country.country_name = r.nationality
