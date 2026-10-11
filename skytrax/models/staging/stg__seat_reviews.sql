with source as (

    select * from {{ source('raw', 'raw_seat_reviews') }}
    where airline_id in (select airline_id from {{ ref('stg__airlines') }})

),

-- keep one row per identical review (same airline, reviewer, day and text); lowest review_id wins
deduplicated as (

    select * from source
    qualify row_number() over (
        partition by airline_id, customer_name, date_submitted, review
        order by review_id
    ) = 1

),

layout_step as (

    select
        *,
        -- 1) hand fixes for values that lost their separators or were mistyped
        case trim(seat_layout)
            when '242'   then '2x4x2'
            when '1X2X'  then '1x2x1'
            when '2xax2' then '3x3'
            else trim(seat_layout)
        end as layout_fixed
    from deduplicated

),

layout_first as (

    select
        *,
        -- 2) keep only the first layout when several are listed ('3x4x3 / 2x4x2', '2x2, 3x3', '... and ...')
        regexp_replace(layout_fixed, '\s*(/|&|;|,|\band\b).*$', '') as layout_first_part
    from layout_step

),

cleaned as (

    select
        review_id,
        airline_id,
        type_of_traveller,
        seat_type,
        aircraft_type,

        -- 3) pull out the digits and join them with 'x' ('3-3-3', '3X3', '3×3', '3 + 3' -> 3x3x3 / 3x3);
        --    anything that is not a 2- or 3-part layout ('Aisle', 'Premium Economy') becomes null
        case
            when regexp_matches(
                    array_to_string(regexp_extract_all(layout_first_part, '[0-9]+'), 'x'),
                    '^[0-9]x[0-9](x[0-9])?$')
            then array_to_string(regexp_extract_all(layout_first_part, '[0-9]+'), 'x')
        end                                                            as seat_layout,

        verify,

        -- the 1970-01-01 placeholder date becomes null
        nullif(date_submitted, date '1970-01-01')                      as date_submitted,

        date_flown,

        -- drop the trailing number (anonymisation suffix)
        trim(regexp_replace(customer_name, ' [0-9]+$', ''))            as customer_name,

        -- nationality that contains a digit is a shifted value ('71J', '3x3x3'): set to null
        case
            when nationality in (select country_name from {{ ref('countries') }})
            then nationality
        end                                                            as nationality,

        seat_legroom,
        seat_recline,
        seat_width,
        aisle_space,
        seat_storage,
        power_supply,
        viewing_tv_screen,
        sleep_comfort,
        sitting_comfort,
        seat_bed_width,
        seat_bed_length,
        seat_privacy,
        recommended,
        review

    from layout_first

)

select * from cleaned