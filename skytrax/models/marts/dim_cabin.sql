-- dim_cabin
-- Grain  : one row per cabin name found in the airline and seat reviews
-- Unknown: already a value in int (cabin_name = 'Unknown'), so it is a normal row here

with cabins as (
    select cabin_name from {{ ref('int__airline_reviews') }}
    union
    select cabin_name from {{ ref('int__seat_reviews') }}
)

select
    cast(row_number() over (order by cabin_name) as integer) as cabin_key,
    cabin_name
from cabins
