{{ config(materialized = "table", schema = "clean") }}


with source as (
   select
       cast(order_id as Int32)          as order_id,
       cast(user_id as Int32)           as user_id,
       cast(eval_set as String)         as eval_set,
       cast(order_number as Int32)      as order_number,
       cast(order_dow as Int32)         as order_dow,
       cast(order_hour_of_day as Int32) as order_hour_of_day,


       -- Parse as Float64; 'nan'/bad -> NULL, then fallback to 0.0 only for those
       coalesce(
           toFloat64OrNull(toString(days_since_prior_order)),
           0.0
       ) as days_since_prior_order
   from {{ source('raw', 'raw___insta_orders') }}
),


cleaned as (
   select
       order_id,
       user_id,
       lower(trim(eval_set)) as eval_set,
       order_number,
       order_dow,
       order_hour_of_day,
       days_since_prior_order
   from source
   where order_id is not null
     and user_id is not null
     and lower(trim(eval_set)) in ('prior','train','test')
)


select * from cleaned
