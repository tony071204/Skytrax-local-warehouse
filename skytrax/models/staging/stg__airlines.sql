select
    airline_id,
    airline_name
from {{ source('raw', 'raw_airlines') }}
where airline_name <> 'Read more'