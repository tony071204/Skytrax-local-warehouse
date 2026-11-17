-- fct_seat_reviews
-- Grain   : one row per seat review (review_id)
-- Source  : int__seat_reviews, keys looked up in the dims
-- Dates   : date_flown_key / date_submitted_key both point to dim_date (role-playing);
--           a missing date maps to the Unknown row (date_key = -1)
-- Scores  : kept NULL when the reviewer did not score a category, so avg() ignores them.
--           Business/First-only scores (sleep, sitting, privacy) are mostly NULL by design.
-- Dropped : seat_bed_width / seat_bed_length (not in the design, filled on ~6% of reviews)

select
    r.review_id,

    case when r.date_flown     is null then -1 else flown.date_key     end as date_flown_key,
    case when r.date_submitted is null then -1 else submitted.date_key end as date_submitted_key,
    airline.airline_key,
    cabin.cabin_key,
    traveller.traveller_type_key,
    country.country_key,
    aircraft.aircraft_key,

    r.verify,

    cast(r.seat_legroom      as double)  as seat_legroom,
    cast(r.seat_recline      as double)  as seat_recline,
    cast(r.seat_width        as double)  as seat_width,
    cast(r.aisle_space       as double)  as aisle_space,
    cast(r.seat_storage      as double)  as seat_storage,
    cast(r.power_supply      as double)  as power_supply,
    cast(r.viewing_tv_screen as double)  as viewing_tv_screen,
    cast(r.sleep_comfort     as double)  as sleep_comfort,
    cast(r.sitting_comfort   as double)  as sitting_comfort,
    cast(r.seat_privacy      as double)  as seat_privacy,

    cast(r.recommended as smallint)      as recommended,
    cast(1 as smallint)                  as review_count

from {{ ref('int__seat_reviews') }} as r
left join {{ ref('dim_date') }}           as flown     on flown.full_date     = r.date_flown
left join {{ ref('dim_date') }}           as submitted on submitted.full_date = r.date_submitted
left join {{ ref('dim_airline') }}        as airline   on airline.airline_id  = r.airline_id
left join {{ ref('dim_cabin') }}          as cabin     on cabin.cabin_name    = r.cabin_name
left join {{ ref('dim_traveller_type') }} as traveller on traveller.traveller_type = r.traveller_type
left join {{ ref('dim_country') }}        as country   on country.country_name = r.nationality
left join {{ ref('dim_aircraft') }}       as aircraft  on aircraft.aircraft_type = r.aircraft_model
                                                       and aircraft.seat_layout   = r.seat_layout
