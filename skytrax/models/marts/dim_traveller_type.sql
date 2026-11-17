-- dim_traveller_type
-- Grain  : one row per traveller type found in the airline, seat, lounge and airport reviews
-- Unknown: already a value in int (traveller_type = 'Unknown'), so it is a normal row here

with traveller_types as (
    select traveller_type from {{ ref('int__airline_reviews') }}
    union
    select traveller_type from {{ ref('int__seat_reviews') }}
    union
    select traveller_type from {{ ref('int__lounge_reviews') }}
    union
    select traveller_type from {{ ref('int__airport_reviews') }}
)

select
    cast(row_number() over (order by traveller_type) as integer) as traveller_type_key,
    traveller_type
from traveller_types
