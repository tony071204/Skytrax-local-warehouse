-- dim_date
-- Grain   : one row per calendar day (+ one 'Unknown' row, date_key = -1)
-- Used by : date_flown / date_visit / date_submitted keys in the fact tables (role-playing dim)
-- Range   : fixed, covers every date in the int review tables (earliest date_submitted is 2002-01-06,
--           latest is 2026-06-20). If a fact has a date outside this range, its relationships test fails.
-- Unknown : reviews without a date (e.g. no date_flown in 2014-15) point to date_key = -1 instead of NULL

with calendar as (
    {{ generate_dates_dimension('2002-01-01', '2026-12-31') }}
),

unknown_date as (
    select
        -1                              as date_key,
        cast(null as date)              as full_date,
        cast(null as smallint)          as day_of_month,
        cast(null as smallint)          as month_number,
        'Unknown'                       as month_name,
        cast(null as smallint)          as quarter_number,
        cast(null as smallint)          as year_number,
        'Unknown'                       as year_month,
        'Unknown'                       as year_quarter
)

select * from calendar
union all
select * from unknown_date
