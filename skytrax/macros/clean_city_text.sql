{# Clean the text of a city in 3 steps.
   "İstanbul (IST)" -> "Istanbul" ; "Heathrow International Airport" -> "Heathrow" ; "ny" -> "New York" #}
{% macro clean_city_text(column_name) %}

    {# Step 1: fix characters (İ, curly apostrophe, zero-width space) and drop "(...)" parts #}
    {%- set city_without_brackets -%}
        regexp_replace(
            replace(replace(replace({{ column_name }}, 'İ', 'I'), '’', ''''), chr(8203), ''),
            '\s*\([^)]*\)', '')
    {%- endset -%}

    {# Step 2: collapse spaces, fix capitals ("St. John'S", "Xi'An"), drop ' International' / ' Airport' endings #}
    {%- set city_with_clean_text -%}
        regexp_replace(
            regexp_replace(
                replace({{ collapse_spaces(city_without_brackets) }}, 'Xi''An', 'Xi''an'),
                '''S\b', '''s'),
            '\s+(International|Intl)?\s*Airport$|\s+International$', '')
    {%- endset -%}

    {# Step 3: spell out the few common abbreviations (any other 1-2 letter value is junk) #}
    case lower({{ city_with_clean_text }})
        when 'kl'  then 'Kuala Lumpur'
        when 'la'  then 'Los Angeles'
        when 'l.a' then 'Los Angeles'
        when 'ny'  then 'New York'
        when 'hk'  then 'Hong Kong'
        when 'dc'  then 'Washington'
        else {{ city_with_clean_text }}
    end
{% endmacro %}


{# True when the text is not a city: symbols or digits, a sentence ("to", "and", "via"), airport words, or shorter than 3 / longer than 30 characters #}
{% macro looks_like_junk_city(column_name) %}
    (
        regexp_matches({{ column_name }}, '[;:=(){}"0-9/&,–\\]')
        or regexp_matches({{ column_name }}, '(?i)\b(to|and|via)\b')
        or regexp_matches({{ column_name }}, '(?i)airport|internation|national|domestic')
        or length({{ column_name }}) not between 3 and 30
    )
{% endmacro %}
