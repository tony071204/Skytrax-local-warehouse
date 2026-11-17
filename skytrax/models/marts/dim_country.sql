-- dim_country
-- Grain  : one row per country in the countries seed, plus 'Unknown' for reviews without a valid nationality
-- Source : the countries seed (every nationality in int is already validated against it in staging)

with countries as (
    select country_name from {{ ref('countries') }}
    union
    select 'Unknown' as country_name
)

select
    cast(row_number() over (order by country_name) as integer) as country_key,
    country_name
from countries
