WITH base AS (
    SELECT * FROM {{ ref('stg_seat_reviews') }}
),

enriched AS (
    SELECT
        review_id,
        airline_id,
        COALESCE(type_of_traveller, 'Unspecified') AS type_of_traveller,
        COALESCE(seat_type, 'Unspecified') AS seat_type,
        COALESCE(aircraft_type, 'Unspecified') AS aircraft_type,
        seat_layout,
        date_submitted,
        date_flown,
        customer_name,
        COALESCE(nationality, 'Unknown') AS nationality,
        is_verified,
        seat_legroom,
        seat_recline,
        seat_width,
        aisle_space,
        seat_storage,
        power_supply,
        viewing_tv_screen,
        sleep_comfort,
        sitting_comfort,
        seat_bed_width,
        seat_bed_length,
        seat_privacy,
        ROUND(
            (
                COALESCE(seat_legroom, 0)
                + COALESCE(seat_recline, 0)
                + COALESCE(seat_width, 0)
                + COALESCE(aisle_space, 0)
                + COALESCE(seat_storage, 0)
                + COALESCE(power_supply, 0)
                + COALESCE(viewing_tv_screen, 0)
                + COALESCE(sleep_comfort, 0)
                + COALESCE(sitting_comfort, 0)
            ) * 1.0 / NULLIF(
                (CASE WHEN seat_legroom IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN seat_recline IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN seat_width IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN aisle_space IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN seat_storage IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN power_supply IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN viewing_tv_screen IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN sleep_comfort IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN sitting_comfort IS NOT NULL THEN 1 ELSE 0 END),
                0
            ),
            2
        ) AS overall_seat_score,
        is_recommended,
        review_text
    FROM base
)

SELECT * FROM enriched
