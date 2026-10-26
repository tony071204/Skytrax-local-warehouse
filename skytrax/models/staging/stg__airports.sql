select
    airport_id,
    airport_name
from {{ source('raw', 'raw_airports') }}
where airport_name <> 'Read more'
