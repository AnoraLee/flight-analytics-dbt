SELECT
    airport_id,
    airport_name
FROM {{ ref('stg_airports') }}