WITH base AS (
    SELECT * FROM {{ ref('stg_airline_reviews') }}
),

enriched AS (
    SELECT
        review_id,
        airline_id,
        date_submitted,
        date_flown,
        customer_name,
        COALESCE(nationality, 'Unknown') AS nationality,
        COALESCE(type_of_traveller, 'Unspecified') AS type_of_traveller,
        COALESCE(seat_type, 'Unspecified') AS seat_type,
        aircraft,
        origin_city,
        origin_airport,
        destination_city,
        destination_airport,
        CASE
            WHEN origin_city IS NOT NULL AND destination_city IS NOT NULL
                THEN origin_city || ' -> ' || destination_city
            ELSE 'Unspecified Route'
        END AS flight_route,
        CASE
            WHEN transit_city IS NOT NULL OR transit_airport IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS is_transit_flight,
        is_verified,
        seat_comfort,
        cabin_staff_service,
        food_and_beverages,
        inflight_entertainment,
        ground_service,
        wifi_and_connectivity,
        value_for_money,
        ROUND(
            (
                COALESCE(seat_comfort, 0)
                + COALESCE(cabin_staff_service, 0)
                + COALESCE(food_and_beverages, 0)
                + COALESCE(inflight_entertainment, 0)
                + COALESCE(ground_service, 0)
                + COALESCE(wifi_and_connectivity, 0)
                + COALESCE(value_for_money, 0)
            ) * 1.0 / NULLIF(
                (CASE WHEN seat_comfort IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN cabin_staff_service IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN food_and_beverages IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN inflight_entertainment IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN ground_service IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN wifi_and_connectivity IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN value_for_money IS NOT NULL THEN 1 ELSE 0 END),
                0
            ),
            2
        ) AS overall_review_score,
        is_recommended,
        review_text
    FROM base
)

SELECT * FROM enriched
