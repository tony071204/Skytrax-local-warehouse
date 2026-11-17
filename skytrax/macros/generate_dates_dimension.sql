{#
    generate_dates_dimension(start_date, end_date)

    Builds a continuous calendar (one row per day) for dim_date, DuckDB syntax.
    Dates are 'YYYY-MM-DD' strings, both ends included.
    Output: the 9 columns of dim_date in the ERD. The 'Unknown' row (date_key = -1) is added by the model.
#}

{% macro generate_dates_dimension(start_date, end_date) %}

with date_spine as (
    select cast(generate_series as date) as full_date
    from generate_series(
        cast('{{ start_date }}' as date),
        cast('{{ end_date }}'   as date),
        interval 1 day
    )
)

select
    cast(strftime(full_date, '%Y%m%d') as integer)       as date_key,
    full_date,
    cast(day(full_date)     as smallint)                 as day_of_month,
    cast(month(full_date)   as smallint)                 as month_number,
    monthname(full_date)                                 as month_name,
    cast(quarter(full_date) as smallint)                 as quarter_number,
    cast(year(full_date)    as smallint)                 as year_number,
    strftime(full_date, '%Y-%m')                         as year_month,
    cast(year(full_date) as varchar) || '-Q' || cast(quarter(full_date) as varchar) as year_quarter
from date_spine

{% endmacro %}
