-- int__lounge_reviews
-- Source  : stg__lounge_reviews (grain: one row per review_id)
-- Purpose : prepare lounge reviews for the mart layer; no rows added or removed
-- Changes : NULL text columns -> 'Unknown' (lounge_name, airport_name, type_of_lounge, nationality, traveller_type);
--           type_of_traveller renamed to traveller_type (only 'Business' or NULL in the source);
--           rating columns cast to integer (NULL kept = no score given);
--           recommended boolean -> 0/1 (smallint)
-- Dropped : customer_name, review text
-- Dates   : date_visit / date_submitted kept as is; NULL date keys are handled in the fact
with source_lounge_reviews as (
    select *
    from {{ ref('stg__lounge_reviews') }}
),

cleaned_lounge_reviews as (
    select
        review_id,
        airline_id,
        date_visit,
        date_submitted,
        verify,

        coalesce(lounge_name, 'Unknown')    as lounge_name,
        coalesce(airport_name, 'Unknown')   as airport_name,
        coalesce(type_of_lounge, 'Unknown') as type_of_lounge,
        coalesce(type_of_traveller, 'Unknown') as traveller_type,
        coalesce(nationality, 'Unknown')    as nationality,

        comfort::integer           as comfort,
        cleanliness::integer       as cleanliness,
        bar_and_beverages::integer as bar_and_beverages,
        catering::integer          as catering,
        washrooms::integer         as washrooms,
        wifi_connectivity::integer as wifi_connectivity,
        staff_service::integer     as staff_service,

        recommended::smallint as recommended
    from source_lounge_reviews
)

select * from cleaned_lounge_reviews
