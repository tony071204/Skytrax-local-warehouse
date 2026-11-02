{# Clean a seat layout into the form 3x3x3 or 3x3, in 3 steps.
   "3-3-3", "3X3X3", "3 + 3 + 3" -> 3x3x3 ; "3x4x3 / 2x4x2" -> 3x4x3 ; "Aisle", "Premium Economy" -> null #}
{% macro clean_seat_layout(column_name) %}

    {# Step 1: hand fixes for values that lost their separators or were mistyped #}
    {%- set seat_layout_fixed -%}
        case trim({{ column_name }})
            when '242'   then '2x4x2'
            when '1X2X'  then '1x2x1'
            when '2xax2' then '3x3'
            else trim({{ column_name }})
        end
    {%- endset -%}

    {# Step 2: when several layouts are listed ("A / B", "A, B", "A and B"), keep only the first #}
    {%- set seat_layout_first_part -%}
        regexp_replace({{ seat_layout_fixed }}, '\s*(/|&|;|,|\band\b).*$', '')
    {%- endset -%}

    {# Step 3: keep the digits joined by 'x'; anything that is not a 2- or 3-part layout becomes null #}
    {%- set seat_layout_digits -%}
        array_to_string(regexp_extract_all({{ seat_layout_first_part }}, '[0-9]+'), 'x')
    {%- endset -%}

    case
        when regexp_matches({{ seat_layout_digits }}, '^[0-9]x[0-9](x[0-9])?$') then {{ seat_layout_digits }}
    end
{% endmacro %}
