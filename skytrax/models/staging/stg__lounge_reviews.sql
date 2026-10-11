with source as (

    select * from {{ source('raw', 'raw_lounge_reviews') }}
    -- drop reviews of the scraped 'Read more' pseudo-airline (not in the cleaned dimension)
    where airline_id in (select airline_id from {{ ref('stg__airlines') }})

),

-- keep one row per identical review (same airline, reviewer, day and text); lowest review_id wins
    deduplicated as (

        select * from source
        qualify row_number() over (
            partition by airline_id, customer_name, date_submitted, review
            order by review_id
        ) = 1

    ),

    -- lounge_name: collapse repeated spaces, drop the scraped ' review' ending,
    -- trim, turn the junk value '=' into null, then upper case
    named as (

        select
            *,
            upper(
                nullif(
                    nullif(
                        trim(regexp_replace(regexp_replace(lounge_name, '\s+', ' ', 'g'), '( lounge) review$', '\1', 'i')),
                        ''
                    ),
                    '='
                )
            ) as name_clean
        from deduplicated

    ),

    -- lounge_name: spelling key = letters and digits only ("SILVER KRIS" = "SILVERKRIS" = "SILVER-KRIS")
    keyed as (

        select
            *,
            nullif(regexp_replace(name_clean, '[^A-Z0-9]', '', 'g'), '') as name_key
        from named

    ),

    -- lounge_name: per key keep the most frequent spelling 
    canonical as (

        select
            name_key,
            name_clean as canonical_name
        from keyed
        where name_key is not null
        group by name_key, name_clean
        qualify row_number() over (
            partition by name_key
            order by count(*) desc, name_clean
        ) = 1

    ),

    cleaned as (

        select
            k.review_id,
            k.airline_id,
            coalesce(c.canonical_name, k.name_clean)                       as lounge_name,

            -- airport: drop the ' Airport' ending (to match airports), collapse repeated spaces
            trim(regexp_replace(regexp_replace(k.airport, ' Airport$', ''), '\s+', ' ', 'g'))
                                                                            as airport_name,

            k.type_of_lounge,
            k.verify,
            k.date_submitted,
            k.date_visit,

            -- customer_name: drop the trailing number (anonymisation suffix)
            trim(regexp_replace(k.customer_name, ' [0-9]+$', ''))          as customer_name,

            -- keep only real countries; anything else becomes null
            case
                when k.nationality in (select country_name from {{ ref('countries') }})
                then k.nationality
            end                                                            as nationality,

            k.comfort,
            k.cleanliness,
            k.bar_and_beverages,
            k.catering,
            k.washrooms,
            k.wifi_connectivity,
            k.staff_service,
            k.recommended,
            k.review

        from keyed k
        left join canonical c on c.name_key = k.name_key

    )

select * from cleaned