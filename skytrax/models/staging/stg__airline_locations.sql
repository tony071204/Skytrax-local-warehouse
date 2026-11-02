-- Cleans the 3 places of a flight (origin, destination, transit), each with a city and an airport.
-- The airport column is reliable, the city column is messy, so the airport is decided first.

-- Lookup lists (lower case), used in step 3 to recognise what a city text is
with known_cities as (
    select distinct lower(city_name) as city_name
    from {{ ref('iata_airports') }}),

known_countries as (
    select distinct lower(country_name) as country_name
    from {{ ref('countries') }}),

-- 1. Unpivot: 1 row per review becomes 3 rows, one per prefix (origin / destination / transit)
-- columns: review_id | prefix | city_original | airport_original
rows_per_prefix as (
    select review_id, 'origin' as prefix, origin_city as city_original, origin_airport as airport_original
    from {{ source('raw', 'raw_airline_reviews') }}
    union all
    select review_id, 'destination', destination_city, destination_airport
    from {{ source('raw', 'raw_airline_reviews') }}
    union all
    select review_id, 'transit', transit_city, transit_airport
    from {{ source('raw', 'raw_airline_reviews') }}),

-- 2. Clean the text of city_original (spaces, brackets, "Airport" endings, abbreviations)
-- columns: review_id | prefix | airport_original | city_clean
clean_city as (
    select
        review_id,
        prefix,
        airport_original,
        {{ clean_city_text('city_original') }} as city_clean
    from rows_per_prefix),

-- 3. Check whether city_clean matches a country or a city in the standard lists
-- columns: review_id | prefix | airport_original | city_clean | matched_country | matched_city
city_matched as (
    select
        clean_city.*,
        known_countries.country_name as matched_country,
        known_cities.city_name as matched_city
    from clean_city
    left join known_countries on lower(city_clean) = known_countries.country_name
    left join known_cities on lower(city_clean) = known_cities.city_name),

-- 4. Split city_clean into types: airport_code, country, city, junk (the first true condition wins)
-- columns: review_id | prefix | airport_original | city_clean | matched_country | matched_city | city_type
city_labelled as (
    select
        *,
        case
            when regexp_matches(city_clean, '^[A-Za-z]{3}$') then 'airport_code'        -- "LHR"
            when matched_country is not null then 'country'                             -- "Germany"
            when matched_city is not null then 'city'                                   -- "Raleigh/Durham" has a "/" but is real
            when {{ looks_like_junk_city('city_clean') }} then 'junk'                   -- "Quito to Cuenca"
            else 'city'
        end as city_type
    from city_matched),

-- 5. Look up the airport in iata_airports (by airport_original, or by the code typed in city_clean) and add its city and country
-- columns: review_id | prefix | airport_original | city_clean | matched_country | matched_city | city_type | airport_code | airport_city | airport_country
airport_info as (
    select
        city_labelled.*,
        iata_airports.airport_code,
        iata_airports.city_name as airport_city,
        iata_airports.country_name as airport_country
    from city_labelled
    left join {{ ref('iata_airports') }} as iata_airports
        on iata_airports.iata_code = coalesce(
            airport_original,
            case when city_type = 'airport_code' then upper(city_clean) end)),

-- 6. Decide the final airport and city for each row
-- airport: airport_original, or the airport found from the code typed in city_clean
-- If city_type = airport_code then city = airport_city           (city_clean "LHR" -> "London")
-- If city_type = junk         then city = airport_city           (city_clean "Quito to Cuenca" + SOF -> "Sofia"; no airport -> null)
-- If city_type = country      then keep city_clean only if the airport is in that country
--                                  ("Kuwait" + KWI -> "Kuwait"), otherwise city = airport_city (or null)
-- If city_type = city         then keep city_clean               ("Sofia" -> "Sofia")
-- columns: review_id | prefix | airport | city
final_per_prefix as (
    select
        review_id,
        prefix,
        coalesce(airport_original, airport_code) as airport,
        case city_type
            when 'airport_code' then airport_city
            when 'junk'         then airport_city
            when 'country'      then case when lower(city_clean) = lower(airport_country)
                                          then city_clean else airport_city end
            else city_clean
        end as city
    from airport_info)

-- 7. Pivot: 3 rows per review become 1 row again (the reverse of step 1)
--    Take the origin rows, then join the destination and transit row of the same review
-- columns: review_id | origin_city | origin_airport | destination_city | destination_airport | transit_city | transit_airport
select
    origin.review_id,
    origin.city as origin_city,
    origin.airport as origin_airport,
    destination.city as destination_city,
    destination.airport as destination_airport,
    transit.city as transit_city,
    transit.airport as transit_airport
from final_per_prefix as origin
join final_per_prefix as destination
    on destination.review_id = origin.review_id and destination.prefix = 'destination'
join final_per_prefix as transit
    on transit.review_id = origin.review_id and transit.prefix = 'transit'
where origin.prefix = 'origin'
