SELECT
    d.airport_id,
    d.airport_name,
    COUNT(f.review_id) AS total_reviews,
    ROUND(AVG(f.queuing_times), 2) AS avg_queuing_score,
    ROUND(AVG(f.terminal_cleanliness), 2) AS avg_cleanliness_score,
    ROUND(AVG(f.airport_staff), 2) AS avg_staff_score,
    ROUND(AVG(f.wifi_connectivity), 2) AS avg_wifi_score,
    ROUND(AVG(f.overall_airport_score), 2) AS avg_overall_airport_score,
    ROUND(AVG(f.is_recommended) * 100.0, 2) AS recommendation_rate_pct
FROM {{ ref('fct_airport_reviews') }} f
JOIN {{ ref('dim_airports') }} d ON f.airport_id = d.airport_id
WHERE f.queuing_times IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(f.review_id) > 20
ORDER BY avg_queuing_score ASC
LIMIT 20
