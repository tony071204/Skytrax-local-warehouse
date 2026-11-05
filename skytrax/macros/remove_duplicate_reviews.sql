{# Keep one row per identical review (same airport/airline, reviewer, day and text): the lowest review_id #}
{% macro remove_duplicate_reviews(relation, entity_id_column) %}
    select *
    from {{ relation }}
    qualify row_number() over (
        partition by {{ entity_id_column }}, customer_name, date_submitted, review
        order by review_id
    ) = 1
{% endmacro %}
