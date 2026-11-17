-- dim_airport
-- Grain   : one row per airport in stg__airports
-- Source  : stg__airports (int__airport_reviews only carries airport_id)

select
    cast(row_number() over (order by airport_id) as integer) as airport_key,
    airport_id,
    airport_name
from {{ ref('stg__airports') }}
