SELECT
    AIRPORT_ID AS airport_id,
    TRIM(AIRPORT_NAME) AS airport_name
FROM {{ source('skytrax_raw', 'RAW_AIRPORTS') }}