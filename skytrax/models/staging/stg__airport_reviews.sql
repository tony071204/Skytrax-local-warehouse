with source as (

    select * from {{ source('raw', 'raw_airport_reviews') }}
    where airport_id in (select airport_id from {{ ref('stg__airports') }})

),

-- keep one row per identical review (same airport, reviewer, day and text); lowest review_id wins
deduplicated as (

    select * from source
    qualify row_number() over (
        partition by airport_id, customer_name, date_submitted, review
        order by review_id
    ) = 1

),

cleaned as (

    select
        review_id,
        airport_id,
        verify,
        date_submitted,
        date_visit,

        -- drop the trailing number (anonymisation suffix)
        trim(regexp_replace(customer_name, ' [0-9]+$', ''))            as customer_name,

        -- keep only real countries; anything else (airport codes, sentences, symbols) becomes null
        case
            when nationality in (select country_name from {{ ref('countries') }})
            then nationality
        end                                                            as nationality,

        experience_at_airport,
        type_of_traveller,
        queuing_times,
        terminal_cleanliness,
        terminal_seating,
        terminal_signs,
        food_beverages,
        airport_shopping,
        airport_staff,
        wifi_connectivity,
        recommended,
        review

    from deduplicated

)

select * from cleaned