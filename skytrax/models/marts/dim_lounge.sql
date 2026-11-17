-- dim_lounge
-- Grain   : one row per (lounge_name, type_of_lounge, airport_name) combination found in the lounge reviews
-- Source  : int__lounge_reviews
-- Unknown : already a value in int (lounge_name 47%, type_of_lounge and airport_name a few %),
--           so it is a normal row here

with lounges as (
    select distinct
        lounge_name,
        type_of_lounge,
        airport_name
    from {{ ref('int__lounge_reviews') }}
)

select
    cast(row_number() over (order by lounge_name, type_of_lounge, airport_name) as integer) as lounge_key,
    lounge_name,
    type_of_lounge,
    airport_name
from lounges
