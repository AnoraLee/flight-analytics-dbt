SELECT
    airline_id,
    airline_name
FROM {{ ref('stg_airlines') }}