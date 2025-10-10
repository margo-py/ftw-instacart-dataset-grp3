{{ config(materialized="table", schema="clean") }}

select
    order_id,
    user_id,
    eval_set,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
from {{ ref('stg_grp3_instacart_orders') }}
