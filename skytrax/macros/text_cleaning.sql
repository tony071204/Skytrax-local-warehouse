{# Several repeated spaces (or tabs) become one space, then trim both ends #}
{% macro collapse_spaces(column_name) %}
    trim(regexp_replace({{ column_name }}, '\s+', ' ', 'g'))
{% endmacro %}


{# Drop the anonymisation number at the end of a name: "John Smith 12" -> "John Smith" #}
{% macro remove_trailing_number(column_name) %}
    trim(regexp_replace({{ column_name }}, ' [0-9]+$', ''))
{% endmacro %}
