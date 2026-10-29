WITH yearly_scores AS (
    SELECT
        EXTRACT(YEAR FROM f.date_submitted) AS review_year,
        f.airline_id,
        d.airline_name,
        COUNT(f.review_id) AS total_reviews,
        AVG(f.overall_review_score) AS avg_score,
        AVG(f.seat_comfort) AS avg_seat_comfort,
        AVG(f.cabin_staff_service) AS avg_cabin_staff,
        AVG(f.food_and_beverages) AS avg_food_beverages,
        AVG(f.ground_service) AS avg_ground_service,
        AVG(f.value_for_money) AS avg_value_for_money,
        AVG(f.is_recommended) * 100.0 AS recommendation_rate_pct
    FROM {{ ref('fct_airline_reviews') }} f
    JOIN {{ ref('dim_airlines') }} d ON f.airline_id = d.airline_id
    WHERE f.date_submitted IS NOT NULL
      AND f.overall_review_score IS NOT NULL
    GROUP BY 1, 2, 3
    HAVING COUNT(f.review_id) >= 10
),

ranked_scores AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY review_year ORDER BY avg_score DESC) AS airline_rank,
        LAG(avg_score) OVER (PARTITION BY airline_id ORDER BY review_year) AS prev_year_score,
        LAG(recommendation_rate_pct) OVER (PARTITION BY airline_id ORDER BY review_year) AS prev_year_rec_rate
    FROM yearly_scores
)

SELECT
    review_year,
    airline_id,
    airline_name,
    total_reviews,
    ROUND(avg_score, 2) AS avg_score,
    ROUND(recommendation_rate_pct, 2) AS recommendation_rate_pct,
    airline_rank,
    ROUND(avg_score - prev_year_score, 2) AS yoy_change,
    ROUND(recommendation_rate_pct - prev_year_rec_rate, 2) AS yoy_rec_rate_change
FROM ranked_scores
ORDER BY review_year DESC, airline_rank ASC
