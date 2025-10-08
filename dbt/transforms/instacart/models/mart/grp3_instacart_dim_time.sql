{{ config(materialized="table", schema="mart") }}

WITH unique_times AS (
    SELECT DISTINCT
        order_dow,
        order_hour_of_day
    FROM {{ ref('stg_grp3_instacart_orders') }}
)

SELECT 
    -- Composite key: dow * 100 + hour (e.g., 0 = Sun 12am, 623 = Sat 11pm)
    (order_dow * 100 + order_hour_of_day) AS time_id,
    
    order_hour_of_day AS hour,
    order_dow AS day_of_week,
    
    -- Day name
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    
    -- Time of day
    CASE 
        WHEN order_hour_of_day BETWEEN 0 AND 5 THEN 'Late Night'
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN order_hour_of_day BETWEEN 18 AND 21 THEN 'Evening'
        ELSE 'Late Night'
    END AS time_of_day,
    
    -- Weekend flag
    CASE WHEN order_dow IN (0, 6) THEN 1 ELSE 0 END AS is_weekend
    
FROM unique_times