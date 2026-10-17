{# Airport name as written in the airports table: fix spaces and drop the ' Airport' ending
   e.g. "London  Heathrow Airport" -> "London Heathrow" #}
{% macro clean_airport_name(column_name) %}
    regexp_replace({{ collapse_spaces(column_name) }}, ' Airport$', '')
{% endmacro %}
