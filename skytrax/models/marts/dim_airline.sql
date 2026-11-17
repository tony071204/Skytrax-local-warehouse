-- dim_airline
-- Grain   : one row per airline in stg__airlines
-- Source  : stg__airlines (id, name) + seed airline_attributes (service_model, region, peer_group)
-- Unknown : airlines not listed in the seed get 'Unknown' (no NULLs)

select
    cast(row_number() over (order by a.airline_id) as integer) as airline_key,
    a.airline_id,
    a.airline_name,
    coalesce(s.service_model, 'Unknown')                       as service_model,
    coalesce(s.region, 'Unknown')                              as region,
    coalesce(s.peer_group, 'Unknown')                          as peer_group
from {{ ref('stg__airlines') }} as a
left join {{ ref('airline_attributes') }} as s
    on a.airline_id = s.airline_id
