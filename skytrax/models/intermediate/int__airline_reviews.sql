-- int__airline_reviews
-- Source  : stg__airline_reviews (grain: one row per review_id)
-- Purpose : prepare airline reviews for the mart layer; no rows added or removed
-- Changes : NULL text columns -> 'Unknown' (cabin_name, nationality, traveller_type);
--           seat_type renamed to cabin_name, type_of_traveller to traveller_type;
--           rating columns cast to integer (NULL kept = no score given);
--           recommended boolean -> 0/1 (smallint)
-- Dropped : route (origin/destination/transit city and airport), aircraft, customer_name, review text
-- Dates   : date_flown / date_submitted kept as is; NULL date keys are handled in the fact
With source_airline_reviews  as (
    Select * 
    from {{ ref('stg__airline_reviews') }}
),

cleaned_null_airline_reviews as (
    Select 
        review_id,
        airline_id,
        date_flown,
        date_submitted,
        verify,
        
        coalesce(seat_type, 'Unknown')         as cabin_name,
        coalesce(nationality, 'Unknown')       as nationality,
        coalesce(type_of_traveller, 'Unknown') as traveller_type,

        seat_comfort:: integer           as seat_comfort,
        cabin_staff_service::integer     as cabin_staff_service,
        food_and_beverages::integer      as food_and_beverages,
        inflight_entertainment::integer  as inflight_entertainment,
        ground_service::integer          as ground_service,
        wifi_and_connectivity::integer   as wifi_and_connectivity,
        value_for_money::integer         as value_for_money,
        recommended::smallint            as recommended
    
    from source_airline_reviews
)

Select * 
from cleaned_null_airline_reviews