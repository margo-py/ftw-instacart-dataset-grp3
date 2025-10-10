{{ config(materialized="table", schema="clean") }}

select distinct
    user_id,
    order_id,
    order_number
from {{ ref('stg_grp3_instacart_orders') }}
