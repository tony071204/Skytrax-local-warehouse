-- Delete airline with name "Read more"
with valid_airlines as (
    select airline_id from {{ ref('stg__airlines') }}),

reviews_of_valid_airlines as (
    select raw_reviews.*
    from {{ source('raw', 'raw_seat_reviews') }} as raw_reviews
    join valid_airlines
        on raw_reviews.airline_id = valid_airlines.airline_id),

-- Clean the values inside each row
seat_reviews_with_cleaned_values as (
    select
        review_id,
        airline_id,
        type_of_traveller,
        seat_type,
        aircraft_type,
        {{ clean_seat_layout('seat_layout') }} as seat_layout,
        verify,
        nullif(date_submitted, date '1970-01-01') as date_submitted,
        date_flown,
        {{ remove_trailing_number('customer_name') }} as customer_name,
        {{ keep_valid_country('nationality') }} as nationality,
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
    from reviews_of_valid_airlines),

-- Delete duplicate reviews
seat_reviews_unique as (
    {{ remove_duplicate_reviews('seat_reviews_with_cleaned_values', 'airline_id') }})

select * from seat_reviews_unique
