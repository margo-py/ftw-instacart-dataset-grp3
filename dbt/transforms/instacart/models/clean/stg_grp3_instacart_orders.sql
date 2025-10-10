{{ config(materialized="table", schema="clean") }}


with source as (
    select
        toInt32OrNull(order_id)           as order_id,
        toInt32OrNull(user_id)            as user_id,
        lower(trim(toString(eval_set)))   as eval_set,
        toInt32OrNull(order_number)       as order_number,
        toInt32OrNull(order_dow)          as order_dow,
        toInt32OrNull(order_hour_of_day)  as order_hour_of_day,


        -- Clean and normalize days_since_prior_order
        case
            when lower(trim(toString(days_since_prior_order))) in ('nan', 'null', '') then null
            when isNaN(toFloat64OrNull(days_since_prior_order)) then null
            when toFloat64OrNull(days_since_prior_order) = 0 then null
            else toFloat64OrNull(days_since_prior_order)
        end as days_since_prior_order


    from {{ source('raw', 'raw___insta_orders') }}
),


cleaned as (
    select
        order_id,
        user_id,
        eval_set,
        order_number,


        -- Map numeric DOW to readable weekday
        case toInt32(order_dow)
            when 0 then 'Sunday'
            when 1 then 'Monday'
            when 2 then 'Tuesday'
            when 3 then 'Wednesday'
            when 4 then 'Thursday'
            when 5 then 'Friday'
            when 6 then 'Saturday'
            else null
        end as order_dow_name,


        order_dow,
        order_hour_of_day,
        days_since_prior_order
    from source
    where order_id is not null
      and user_id is not null
      and eval_set in ('prior', 'train', 'test')
)


select *
from cleaned






-- {{ config(materialized = "table", schema = "clean") }}


-- with source as (
--    select
--        cast(order_id as Int32)          as order_id,
--        cast(user_id as Int32)           as user_id,
--        cast(eval_set as String)         as eval_set,
--        cast(order_number as Int32)      as order_number,
--        cast(order_dow as Int32)         as order_dow,
--        cast(order_hour_of_day as Int32) as order_hour_of_day,


--        -- Parse as Float64; 'nan'/bad -> NULL, then fallback to 0.0 only for those
--        coalesce(
--            toFloat64OrNull(toString(days_since_prior_order)),
--            0.0
--        ) as days_since_prior_order
--    from {{ source('raw', 'raw___insta_orders') }}
-- ),


-- cleaned as (
--    select
--        order_id,
--        user_id,
--        lower(trim(eval_set)) as eval_set,
--        order_number,
--        order_dow,
--        order_hour_of_day,
--        days_since_prior_order
--    from source
--    where order_id is not null
--      and user_id is not null
--      and lower(trim(eval_set)) in ('prior','train','test')
-- )

-- select * from cleaned
