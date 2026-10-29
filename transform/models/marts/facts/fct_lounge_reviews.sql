WITH base AS (
    SELECT * FROM {{ ref('stg_lounge_reviews') }}
),

enriched AS (
    SELECT
        review_id,
        airline_id,
        COALESCE(lounge_name, 'Unspecified Lounge') AS lounge_name,
        COALESCE(airport, 'Unspecified Airport') AS airport,
        COALESCE(type_of_lounge, 'Unspecified') AS type_of_lounge,
        COALESCE(type_of_traveller, 'Unspecified') AS type_of_traveller,
        date_submitted,
        date_visit,
        customer_name,
        COALESCE(nationality, 'Unknown') AS nationality,
        is_verified,
        comfort,
        cleanliness,
        bar_and_beverages,
        catering,
        washrooms,
        wifi_connectivity,
        staff_service,
        ROUND(
            (
                COALESCE(comfort, 0)
                + COALESCE(cleanliness, 0)
                + COALESCE(bar_and_beverages, 0)
                + COALESCE(catering, 0)
                + COALESCE(washrooms, 0)
                + COALESCE(wifi_connectivity, 0)
                + COALESCE(staff_service, 0)
            ) * 1.0 / NULLIF(
                (CASE WHEN comfort IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN cleanliness IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN bar_and_beverages IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN catering IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN washrooms IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN wifi_connectivity IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN staff_service IS NOT NULL THEN 1 ELSE 0 END),
                0
            ),
            2
        ) AS overall_lounge_score,
        is_recommended,
        review_text
    FROM base
)

SELECT * FROM enriched
