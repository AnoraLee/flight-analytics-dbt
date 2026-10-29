WITH lounge_scores AS (
    SELECT
        airline_id,
        COUNT(review_id) AS total_lounge_reviews,
        AVG(overall_lounge_score) AS lounge_score,
        AVG(comfort) AS avg_lounge_comfort,
        AVG(cleanliness) AS avg_lounge_cleanliness,
        AVG(staff_service) AS avg_lounge_staff_service
    FROM {{ ref('fct_lounge_reviews') }}
    WHERE overall_lounge_score IS NOT NULL
    GROUP BY 1
),

seat_scores AS (
    SELECT
        airline_id,
        COUNT(review_id) AS total_seat_reviews,
        AVG(overall_seat_score) AS seat_score,
        AVG(seat_legroom) AS avg_seat_legroom,
        AVG(seat_recline) AS avg_seat_recline,
        AVG(sitting_comfort) AS avg_sitting_comfort
    FROM {{ ref('fct_seat_reviews') }}
    WHERE overall_seat_score IS NOT NULL
    GROUP BY 1
)

SELECT
    d.airline_id,
    d.airline_name,
    COALESCE(l.total_lounge_reviews, 0) AS total_lounge_reviews,
    COALESCE(s.total_seat_reviews, 0) AS total_seat_reviews,
    ROUND(l.lounge_score, 2) AS lounge_score,
    ROUND(s.seat_score, 2) AS seat_score,
    ROUND((l.lounge_score + s.seat_score) / 2.0, 2) AS total_amenities_score
FROM {{ ref('dim_airlines') }} d
JOIN lounge_scores l ON d.airline_id = l.airline_id
JOIN seat_scores s ON d.airline_id = s.airline_id
WHERE l.lounge_score IS NOT NULL
  AND s.seat_score IS NOT NULL
ORDER BY total_amenities_score DESC
