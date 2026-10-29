WITH base AS (
    SELECT * FROM {{ ref('stg_airport_reviews') }}
),

enriched AS (
    SELECT
        review_id,
        airport_id,
        date_submitted,
        date_visit,
        customer_name,
        COALESCE(nationality, 'Unknown') AS nationality,
        COALESCE(experience_at_airport, 'Unspecified') AS experience_at_airport,
        COALESCE(type_of_traveller, 'Unspecified') AS type_of_traveller,
        is_verified,
        queuing_times,
        terminal_cleanliness,
        terminal_seating,
        terminal_signs,
        food_beverages,
        airport_shopping,
        airport_staff,
        wifi_connectivity,
        ROUND(
            (
                COALESCE(queuing_times, 0)
                + COALESCE(terminal_cleanliness, 0)
                + COALESCE(terminal_seating, 0)
                + COALESCE(terminal_signs, 0)
                + COALESCE(food_beverages, 0)
                + COALESCE(airport_shopping, 0)
                + COALESCE(airport_staff, 0)
                + COALESCE(wifi_connectivity, 0)
            ) * 1.0 / NULLIF(
                (CASE WHEN queuing_times IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN terminal_cleanliness IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN terminal_seating IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN terminal_signs IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN food_beverages IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN airport_shopping IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN airport_staff IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN wifi_connectivity IS NOT NULL THEN 1 ELSE 0 END),
                0
            ),
            2
        ) AS overall_airport_score,
        is_recommended,
        review_text
    FROM base
)

SELECT * FROM enriched
