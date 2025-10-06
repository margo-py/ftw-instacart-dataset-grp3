{{ config(materialized="view", schema="mart") }}

-- Row-level drilldown of “obviously wrong” records based on simple rules.
-- LIMIT for demo-friendliness; remove in real pipelines.

with cln as (
  select * from {{ ref('mpg_standardized') }}
),
violations as (
  select
    -- NOTE: this dataset has no native PK; include a synthetic row_number if needed.
    -- ClickHouse: use monotonicallyIncreasingId() isn't stable; we’ll show columns directly.
    mpg, cylinders, displacement, horsepower, weight, acceleration, model_year, origin, make,

    multiIf(
      mpg <= 0,                      'nonpositive_mpg',
      displacement <= 0,             'nonpositive_displacement',
      weight <= 0,                   'nonpositive_weight',
      acceleration <= 0,             'nonpositive_acceleration',
      cylinders not in (3,4,5,6,8),  'invalid_cylinders',
      lower(origin) not in ('usa','europe','japan'), 'invalid_origin',
      model_year < 70 or model_year > 82, 'out_of_range_model_year',
      horsepower is null,            'null_horsepower',
      'ok'
    ) as dq_issue
  from cln
)
select *
from violations
where dq_issue != 'ok'
limit 50
