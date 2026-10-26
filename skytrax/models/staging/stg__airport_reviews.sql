-- Delete airport with name "Read more"
with valid_airports as (
    select airport_id from {{ ref('stg__airports') }}
),

reviews_of_valid_airports as (
    select raw_reviews.*
    from {{ source('raw', 'raw_airport_reviews') }} as raw_reviews
    join valid_airports
        on raw_reviews.airport_id = valid_airports.airport_id
),

-- Clean the values inside each row 
airport_reviews_with_cleaned_values as (
    select
        review_id,
        airport_id,
        verify,
        date_submitted,
        date_visit,
        {{ remove_trailing_number('customer_name') }} as customer_name,
        {{ keep_valid_country('nationality') }} as nationality,
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
    from reviews_of_valid_airports
),

-- Delete duplicate reviews
airport_reviews_unique as (
    {{ remove_duplicate_reviews('airport_reviews_with_cleaned_values', 'airport_id') }}
)

select * from airport_reviews_unique
