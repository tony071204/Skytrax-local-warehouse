-- dim_aircraft
-- Grain   : one row per (aircraft_type, seat_layout) combination found in the seat reviews
-- Source  : int__seat_reviews (aircraft_model is renamed aircraft_type, as in the ERD)
-- Unknown : already a value in int ('Unknown' aircraft or layout), so it is a normal row here

with aircraft as (
    select distinct
        aircraft_model as aircraft_type,
        seat_layout
    from {{ ref('int__seat_reviews') }}
)

select
    cast(row_number() over (order by aircraft_type, seat_layout) as integer) as aircraft_key,
    aircraft_type,
    seat_layout
from aircraft
