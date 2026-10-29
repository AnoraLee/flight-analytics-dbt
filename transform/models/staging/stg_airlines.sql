SELECT
    AIRLINE_ID AS airline_id,
    TRIM(AIRLINE_NAME) AS airline_name
FROM {{ source('skytrax_raw', 'RAW_AIRLINES') }}