{# Clean a lounge name in 4 steps. All lounge name become consistent using the most used spelling #}
{% macro clean_lounge_name(column_name) %}

    {# Step 1: fix spaces and drop the ' review' ending #}
    {%- set lounge_name_without_review_ending -%}
        regexp_replace({{ collapse_spaces(column_name) }}, '( lounge) review$', '\1', 'i')
    {%- endset -%}

    {# Step 2: junk values ('' and '=') become null, the rest is upper case #}
    {%- set lounge_standard_name -%}
        case
            when {{ lounge_name_without_review_ending }} in ('', '=') then null
            else upper({{ lounge_name_without_review_ending }})
        end
    {%- endset -%}

    {# Step 3: key with letters and digits only, so spellings of one lounge share it
       e.g. "NO.1 LOUNGE" -> NO1LOUNGE, "NO 1 LOUNGE" -> NO1LOUNGE, "ADMIRAL'S CLUB" -> ADMIRALSCLUB, "A-B" -> AB #}
    {%- set match_key -%}
        nullif(regexp_replace({{ lounge_standard_name }}, '[^A-Z0-9]', '', 'g'), '')
    {%- endset -%}

    {# Step 4: the most used standard name among rows with the same key #}
    case
        when {{ match_key }} is null then {{ lounge_standard_name }}
        else mode({{ lounge_standard_name }}) over (partition by {{ match_key }})
    end
{% endmacro %}
