-- Review 26647 is a real United review under the pseudo-airline 419: move it to United (547)
with airline_reviews_with_fixed_airline as (
    select
        * exclude (airline_id),
        case when review_id = 26647 then 547 else airline_id end as airline_id
    from {{ source('raw', 'raw_airline_reviews') }}),

-- Delete airline with name "Read more"
valid_airlines as (
    select airline_id from {{ ref('stg__airlines') }}),

reviews_of_valid_airlines as (
    select reviews.*
    from airline_reviews_with_fixed_airline as reviews
    join valid_airlines
        on reviews.airline_id = valid_airlines.airline_id),

-- Clean the values inside each row; origin, destination and transit come from stg__airline_locations
airline_reviews_with_cleaned_values as (
    select
        reviews.review_id,
        reviews.airline_id,
        reviews.verify,
        reviews.date_submitted,
        -- a flight date after the review date is impossible: set to null
        case when reviews.date_flown > reviews.date_submitted then null else reviews.date_flown end as date_flown,
        {{ remove_trailing_number('reviews.customer_name') }} as customer_name,
        {{ keep_valid_country('reviews.nationality') }} as nationality,
        reviews.type_of_traveller,
        reviews.seat_type,
        reviews.aircraft,
        locations.origin_city,
        locations.origin_airport,
        locations.destination_city,
        locations.destination_airport,
        locations.transit_city,
        locations.transit_airport,
        reviews.seat_comfort,
        reviews.cabin_staff_service,
        reviews.food_and_beverages,
        reviews.inflight_entertainment,
        reviews.ground_service,
        reviews.wifi_and_connectivity,
        reviews.value_for_money,
        reviews.recommended,
        reviews.review
    from reviews_of_valid_airlines as reviews
    left join {{ ref('stg__airline_locations') }} as locations
        on locations.review_id = reviews.review_id),

-- Delete duplicate reviews
airline_reviews_unique as (
    {{ remove_duplicate_reviews('airline_reviews_with_cleaned_values', 'airline_id') }})

select * from airline_reviews_unique
