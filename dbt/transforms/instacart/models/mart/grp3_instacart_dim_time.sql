{{ config(materialized='table', schema='mart', order_by='tuple()') }}

select 
    cast(row_number() over () as integer) as time_id,
    cast(order_dow as integer) as order_dow,
    case 
        when order_dow = 0 then 'sunday'
        when order_dow = 1 then 'monday'
        when order_dow = 2 then 'tuesday'
        when order_dow = 3 then 'wednesday'
        when order_dow = 4 then 'thursday'
        when order_dow = 5 then 'friday'
        when order_dow = 6 then 'saturday'
        else 'unknown'
    end as day_name,
    cast(order_hour_of_day as integer) as order_hour_of_day,
    case 
        when order_hour_of_day between 0 and 5 then 'late night'
        when order_hour_of_day between 6 and 11 then 'morning'
        when order_hour_of_day between 12 and 17 then 'afternoon'
        when order_hour_of_day between 18 and 21 then 'evening'
        else 'late night'
    end as time_of_day,
    case when order_dow in (0, 6) then 1 else 0 end as is_weekend
from (
    select distinct
        order_dow,
        order_hour_of_day
    from {{ ref('stg_nrml_grp3_instacart_order_details') }}
    where order_dow is not null
)

-- {{ config(materialized="table", schema="mart") }}

-- WITH unique_times AS (
--     SELECT DISTINCT
--         order_dow,
--         order_hour_of_day
--     FROM {{ ref('stg_grp3_instacart_orders') }}
-- )

-- SELECT 
--     -- Composite key: dow * 100 + hour (e.g., 0 = Sun 12am, 623 = Sat 11pm)
--     (order_dow * 100 + order_hour_of_day) AS time_id,
    
--     order_hour_of_day AS hour,
--     order_dow AS day_of_week,
    
--     -- Day name
--     CASE order_dow
--         WHEN 0 THEN 'Sunday'
--         WHEN 1 THEN 'Monday'
--         WHEN 2 THEN 'Tuesday'
--         WHEN 3 THEN 'Wednesday'
--         WHEN 4 THEN 'Thursday'
--         WHEN 5 THEN 'Friday'
--         WHEN 6 THEN 'Saturday'
--     END AS day_name,
    
--     -- Time of day
--     CASE 
--         WHEN order_hour_of_day BETWEEN 0 AND 5 THEN 'Late Night'
--         WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
--         WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
--         WHEN order_hour_of_day BETWEEN 18 AND 21 THEN 'Evening'
--         ELSE 'Late Night'
--     END AS time_of_day,
    
--     -- Weekend flag
--     CASE WHEN order_dow IN (0, 6) THEN 1 ELSE 0 END AS is_weekend
    
-- FROM unique_times
