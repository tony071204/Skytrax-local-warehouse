-- fct_lounge_reviews
-- Grain   : one row per lounge review (review_id)
-- Source  : int__lounge_reviews, keys looked up in the dims
-- Dates   : date_visit_key / date_submitted_key both point to dim_date (role-playing);
--           a missing date maps to the Unknown row (date_key = -1). date_visit is empty on ~45% of reviews.
-- Scores  : kept NULL when the reviewer did not score a category, so avg() ignores them
-- No cabin_key: the class of the lounge (Business, First, ...) is type_of_lounge in dim_lounge

select
    r.review_id,

    case when r.date_visit     is null then -1 else visit.date_key     end as date_visit_key,
    case when r.date_submitted is null then -1 else submitted.date_key end as date_submitted_key,
    airline.airline_key,
    lounge.lounge_key,
    traveller.traveller_type_key,
    country.country_key,

    r.verify,

    cast(r.comfort           as double)  as comfort,
    cast(r.cleanliness       as double)  as cleanliness,
    cast(r.bar_and_beverages as double)  as bar_and_beverages,
    cast(r.catering          as double)  as catering,
    cast(r.washrooms         as double)  as washrooms,
    cast(r.wifi_connectivity as double)  as wifi_connectivity,
    cast(r.staff_service     as double)  as staff_service,

    cast(r.recommended as smallint)      as recommended,
    cast(1 as smallint)                  as review_count

from {{ ref('int__lounge_reviews') }} as r
left join {{ ref('dim_date') }}           as visit     on visit.full_date     = r.date_visit
left join {{ ref('dim_date') }}           as submitted on submitted.full_date = r.date_submitted
left join {{ ref('dim_airline') }}        as airline   on airline.airline_id  = r.airline_id
left join {{ ref('dim_lounge') }}         as lounge    on lounge.lounge_name    = r.lounge_name
                                                       and lounge.type_of_lounge = r.type_of_lounge
                                                       and lounge.airport_name   = r.airport_name
left join {{ ref('dim_traveller_type') }} as traveller on traveller.traveller_type = r.traveller_type
left join {{ ref('dim_country') }}        as country   on country.country_name = r.nationality
