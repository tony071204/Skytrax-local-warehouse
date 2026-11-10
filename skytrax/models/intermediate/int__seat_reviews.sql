-- int__seat_reviews
-- Source  : stg__seat_reviews (grain: one row per review_id)
-- Purpose : prepare seat reviews for the mart layer; no rows added or removed
-- Changes : NULL text columns -> 'Unknown' (cabin_name, nationality, traveller_type, aircraft_model, seat_layout);
--           seat_type renamed to cabin_name, type_of_traveller to traveller_type, aircraft_type to aircraft_model;
--           rating columns cast to integer (NULL kept = no score given);
--           recommended boolean -> 0/1 (smallint)
-- Kept    : seat_bed_* and other mostly-NULL ratings (~94% NULL); decide in the fact whether to drop them
-- Dropped : customer_name, review text
-- Dates   : date_flown / date_submitted kept as is; NULL date keys are handled in the fact
with source_seat_reviews as (
    select *
    from {{ ref('stg__seat_reviews') }}
),

cleaned_seat_reviews as (
    select
        review_id,
        airline_id,
        date_flown,
        date_submitted,
        verify,

        coalesce(seat_type, 'Unknown')         as cabin_name,
        coalesce(nationality, 'Unknown')       as nationality,
        coalesce(type_of_traveller, 'Unknown') as traveller_type,
        coalesce(aircraft_type, 'Unknown')     as aircraft_model,
        coalesce(seat_layout, 'Unknown')       as seat_layout,

        seat_legroom::integer      as seat_legroom,
        seat_recline::integer      as seat_recline,
        seat_width::integer        as seat_width,
        aisle_space::integer       as aisle_space,
        seat_storage::integer      as seat_storage,
        power_supply::integer      as power_supply,
        viewing_tv_screen::integer as viewing_tv_screen,
        sleep_comfort::integer     as sleep_comfort,
        sitting_comfort::integer   as sitting_comfort,
        seat_bed_width::integer    as seat_bed_width,
        seat_bed_length::integer   as seat_bed_length,
        seat_privacy::integer      as seat_privacy,

        recommended::smallint as recommended
    from source_seat_reviews
)

select * from cleaned_seat_reviews