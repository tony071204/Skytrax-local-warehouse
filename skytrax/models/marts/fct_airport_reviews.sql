-- fct_airport_reviews
-- Grain   : one row per airport review (review_id)
-- Source  : int__airport_reviews, keys looked up in the dims
-- Link    : independent fact. It has no airline_key because airport reviews cannot be tied
--           to an airline reliably.
-- Dates   : date_visit_key / date_submitted_key both point to dim_date (role-playing);
--           a missing date maps to the Unknown row (date_key = -1). date_visit is empty on ~35% of reviews.
-- Scores  : kept NULL when the reviewer did not score a category, so avg() ignores them
--           (wifi is empty on ~56% of reviews)

select
    r.review_id,

    case when r.date_visit     is null then -1 else visit.date_key     end as date_visit_key,
    case when r.date_submitted is null then -1 else submitted.date_key end as date_submitted_key,
    airport.airport_key,
    experience.airport_experience_key,
    traveller.traveller_type_key,
    country.country_key,

    r.verify,

    cast(r.queuing_times        as double)  as queuing_times,
    cast(r.terminal_cleanliness as double)  as terminal_cleanliness,
    cast(r.terminal_seating     as double)  as terminal_seating,
    cast(r.terminal_signs       as double)  as terminal_signs,
    cast(r.food_beverages       as double)  as food_beverages,
    cast(r.airport_shopping     as double)  as airport_shopping,
    cast(r.airport_staff        as double)  as airport_staff,
    cast(r.wifi_connectivity    as double)  as wifi_connectivity,

    cast(r.recommended as smallint)         as recommended,
    cast(1 as smallint)                     as review_count

from {{ ref('int__airport_reviews') }} as r
left join {{ ref('dim_date') }}                as visit      on visit.full_date     = r.date_visit
left join {{ ref('dim_date') }}                as submitted  on submitted.full_date = r.date_submitted
left join {{ ref('dim_airport') }}             as airport    on airport.airport_id  = r.airport_id
left join {{ ref('dim_airport_experience') }}  as experience on experience.airport_experience = r.airport_experience
left join {{ ref('dim_traveller_type') }}      as traveller  on traveller.traveller_type = r.traveller_type
left join {{ ref('dim_country') }}             as country    on country.country_name = r.nationality
