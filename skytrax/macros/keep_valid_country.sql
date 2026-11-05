{% macro keep_valid_country(column_name) %}
    (
        select country_name
        from {{ ref('countries') }}
        where lower(country_name) = lower(trim({{ column_name }}))
    )
{% endmacro %}
