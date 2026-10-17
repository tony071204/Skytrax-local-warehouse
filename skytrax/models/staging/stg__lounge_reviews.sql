-- Delete airline with name "Read more"
with valid_airlines as (
    select airline_id from {{ ref('stg__airlines') }}),

reviews_of_valid_airlines as (
    select raw_reviews.*
    from {{ source('raw', 'raw_lounge_reviews') }} as raw_reviews
    join valid_airlines
        on raw_reviews.airline_id = valid_airlines.airline_id),

-- Clean the values inside each row
lounge_reviews_with_cleaned_values as (
    select
        review_id,
        airline_id,
        {{ clean_lounge_name('lounge_name') }} as lounge_name,
        {{ clean_airport_name('airport') }} as airport_name,
        type_of_lounge,
        verify,
        date_submitted,
        date_visit,
        {{ remove_trailing_number('customer_name') }} as customer_name,
        {{ keep_valid_country('nationality') }} as nationality,
        comfort,
        cleanliness,
        bar_and_beverages,
        catering,
        washrooms,
        wifi_connectivity,
        staff_service,
        recommended,
        review
    from reviews_of_valid_airlines),

-- Delete duplicate reviews
lounge_reviews_unique as (
    {{ remove_duplicate_reviews('lounge_reviews_with_cleaned_values', 'airline_id') }})

select * from lounge_reviews_unique
