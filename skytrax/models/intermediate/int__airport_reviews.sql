-- int__airport_reviews
-- Source  : stg__airport_reviews (grain: one row per review_id)
-- Purpose : prepare airport reviews for the mart layer; no rows added or removed
-- Changes : NULL text columns -> 'Unknown' (airport_experience, traveller_type, nationality);
--           experience_at_airport renamed to airport_experience, type_of_traveller to traveller_type;
--           rating columns cast to integer (NULL kept = no score given);
--           recommended boolean -> 0/1 (smallint)
-- Note    : no airline_id; airport reviews cannot be linked to airlines reliably
-- Dropped : customer_name, review text
-- Dates   : date_visit / date_submitted kept as is; NULL date keys are handled in the fact
with source_airport_reviews as (
    select *
    from {{ ref('stg__airport_reviews') }}
),

cleaned_airport_reviews as (
    select
        review_id,
        airport_id,
        date_visit,
        date_submitted,
        verify,

        coalesce(experience_at_airport, 'Unknown') as airport_experience,
        coalesce(type_of_traveller, 'Unknown')     as traveller_type,
        coalesce(nationality, 'Unknown')           as nationality,

        queuing_times::integer        as queuing_times,
        terminal_cleanliness::integer as terminal_cleanliness,
        terminal_seating::integer     as terminal_seating,
        terminal_signs::integer       as terminal_signs,
        food_beverages::integer       as food_beverages,
        airport_shopping::integer     as airport_shopping,
        airport_staff::integer        as airport_staff,
        wifi_connectivity::integer    as wifi_connectivity,

        recommended::smallint as recommended
    from source_airport_reviews
)

select * from cleaned_airport_reviews
