WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('2010-01-01')",
        end_date="to_date('2030-12-31')"
    ) }}
)

SELECT
    CAST(date_day AS DATE)              AS date_key,
    EXTRACT(YEAR FROM date_day)          AS year,
    EXTRACT(QUARTER FROM date_day)       AS quarter,
    EXTRACT(MONTH FROM date_day)         AS month,
    EXTRACT(DAY FROM date_day)           AS day,
    EXTRACT(DAYOFWEEK FROM date_day)     AS day_of_week,
    TO_CHAR(date_day, 'YYYY-MM')         AS year_month
FROM date_spine