{{ config(materialized="table", schema="clean") }}

select
    cast(product_id as Int32) as product_id,
    product_name,
    cast(aisle_id as Int32) as aisle_id
from {{ ref('stg_grp3_instacart_products') }}
