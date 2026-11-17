-- dim_airport_experience
-- Grain  : one row per airport experience found in the airport reviews
--          (Departure Only, Arrival Only, Arrival and Departure, Transit, Unknown)
-- Unknown: already a value in int, so it is a normal row here

with experiences as (
    select distinct airport_experience
    from {{ ref('int__airport_reviews') }}
)

select
    cast(row_number() over (order by airport_experience) as integer) as airport_experience_key,
    airport_experience
from experiences
