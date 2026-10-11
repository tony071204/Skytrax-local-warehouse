with source as (

    -- review 26647 is a real United review stuck under the scraped 'Read more' pseudo-airline (419)
    select
        * exclude (airline_id),
        case when review_id = 26647 then 547 else airline_id end as airline_id
    from {{ source('raw', 'raw_airline_reviews') }}

),

-- drop reviews of airlines that are not in the cleaned dimension ('Read more' copies)
valid_airline as (

    select * from source
    where airline_id in (select airline_id from {{ ref('stg__airlines') }})

),

-- keep one row per identical review (same airline, reviewer, day and text); lowest review_id wins
deduplicated as (

    select * from valid_airline
    qualify row_number() over (
        partition by airline_id, customer_name, date_submitted, review
        order by review_id
    ) = 1

),

-- route: put origin / destination / transit in one column pair so the cleaning is written once
legs as (

    select review_id, 'origin' as leg, origin_airport as airport_raw, origin_city as city_raw from deduplicated
    union all
    select review_id, 'destination', destination_airport, destination_city from deduplicated
    union all
    select review_id, 'transit', transit_airport, transit_city from deduplicated

),

-- city step 1: fix characters (İ, curly apostrophe, zero-width space), drop '(...)' parts, collapse spaces,
-- fix "St. John'S" style capitals, drop ' International' / ' Airport' endings
legs_text as (

    select
        review_id,
        leg,
        airport_raw,
        regexp_replace(
            regexp_replace(
                replace(trim(regexp_replace(
                    regexp_replace(
                        replace(replace(replace(city_raw, 'İ', 'I'), '’', ''''), chr(8203), ''),
                        '\s*\([^)]*\)', ''),
                    '\s+', ' ', 'g')), 'Xi''An', 'Xi''an'),
                '''S\b', '''s'),
            '\s+(International|Intl)?\s*Airport$|\s+International$', ''
        ) as city_text
    from legs

),

-- city step 2: spell out the few common abbreviations (any other 1-2 letter value is junk, see below)
legs_abbrev as (

    select
        review_id,
        leg,
        airport_raw,
        case lower(city_text)
            when 'kl'  then 'Kuala Lumpur'
            when 'la'  then 'Los Angeles'
            when 'l.a' then 'Los Angeles'
            when 'ny'  then 'New York'
            when 'hk'  then 'Hong Kong'
            when 'dc'  then 'Washington'
            else city_text
        end as city_text
    from legs_text

),

-- city step 3: classify the cleaned text
legs_flags as (

    select
        *,
        -- three letters = an airport code typed into the city column ('Sgn', 'Fll')
        regexp_matches(city_text, '^[A-Za-z]{3}$') as is_code,
        -- junk: stray symbols or digits, sentences, two places in one value, airport words, over 30 characters
        -- (a value that is exactly a city name from iata_airports, e.g. 'Raleigh/Durham', is never junk)
        (   (   regexp_matches(city_text, '[;:=\{\}"\\0-9/&,–]')
            or regexp_matches(city_text, '(?i)\b(to|and|via)\b')
            or regexp_matches(city_text, '(?i)airport|internation|national|domestic')
            or length(city_text) > 30
            or length(city_text) <= 2
            )
            and not (length(city_text) > 2
                    and lower(city_text) in (select lower(city_name) from {{ ref('iata_airports') }}))
        ) as is_junk
    from legs_abbrev

),

-- city step 4: look up the airport (existing airport column) and the code typed in the city column
legs_lookup as (

    select
        f.review_id,
        f.leg,
        f.airport_raw,
        f.city_text,
        f.is_code,
        f.is_junk,
        a.city_name        as airport_city,
        a.country_name     as airport_country,
        c.airport_code     as code_airport,
        c.city_name        as code_city
    from legs_flags f
    left join {{ ref('iata_airports') }} a on a.iata_code = f.airport_raw
    left join {{ ref('iata_airports') }} c on f.is_code and c.iata_code = upper(f.city_text)

),

legs_final as (

    select
        review_id,
        leg,

        -- airport: keep what is there; if empty and the city column holds a real airport code, use that code
        coalesce(airport_raw, code_airport) as airport_final,

        case
            -- a code typed in the city column becomes the real city name
            when is_code then coalesce(airport_city, code_city)
            -- junk or too short: use the city of the airport if we know it, otherwise null
            when is_junk then airport_city
            -- a country name is kept only when the airport is in that same country
            when lower(city_text) in (select lower(country_name) from {{ ref('countries') }})
                then case when lower(city_text) = lower(airport_country) then city_text else airport_city end
            else city_text
        end as city_final

    from legs_lookup

),

route as (

    select
        review_id,
        max(case when leg = 'origin'      then city_final    end) as origin_city,
        max(case when leg = 'origin'      then airport_final end) as origin_airport,
        max(case when leg = 'destination' then city_final    end) as destination_city,
        max(case when leg = 'destination' then airport_final end) as destination_airport,
        max(case when leg = 'transit'     then city_final    end) as transit_city,
        max(case when leg = 'transit'     then airport_final end) as transit_airport
    from legs_final
    group by review_id

),

cleaned as (

    select
        d.review_id,
        d.airline_id,
        d.verify,
        d.date_submitted,

        -- a flight date after the review date is impossible: set to null
        case when d.date_flown > d.date_submitted then null else d.date_flown end as date_flown,

        -- drop the trailing number (anonymisation suffix)
        trim(regexp_replace(d.customer_name, ' [0-9]+$', ''))          as customer_name,

        -- keep only real countries (case-insensitive match, spelling taken from the seed)
        n.country_name                                                 as nationality,

        d.type_of_traveller,
        d.seat_type,
        d.aircraft,
        r.origin_city,
        r.origin_airport,
        r.destination_city,
        r.destination_airport,
        r.transit_city,
        r.transit_airport,
        d.seat_comfort,
        d.cabin_staff_service,
        d.food_and_beverages,
        d.inflight_entertainment,
        d.ground_service,
        d.wifi_and_connectivity,
        d.value_for_money,
        d.recommended,
        d.review

    from deduplicated d
    left join route r on r.review_id = d.review_id
    left join {{ ref('countries') }} n on lower(trim(d.nationality)) = lower(n.country_name)

)

select * from cleaned