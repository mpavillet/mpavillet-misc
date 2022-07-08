set ref_date='2022-07-01';
set credit_price=3;

with base as (
SELECT
    query_id AS snowflake_query_id,
    database_name,
    schema_name,    
    query_text,
    role_name,
    rows_produced AS query_result_rows_produced,
    user_name,
    warehouse_name,
    warehouse_id,
    warehouse_size,
    CONVERT_TIMEZONE('UTC', end_time) as end_time,
    CONVERT_TIMEZONE('UTC', start_time) as start_time,
    date(CONVERT_TIMEZONE('UTC', start_time)) as usage_day,
    start_time as start_time_pacific_time,
    end_time as end_time_pacific_time,    
    total_elapsed_time as total_elapsed_time_ms,
    total_elapsed_time/1000 as total_elapsed_time,
    CASE warehouse_size
      WHEN 'X-Small' THEN 1
      WHEN 'Small' THEN 2
      WHEN 'Medium' THEN 4
      WHEN 'Large' THEN 8
      WHEN 'X-Large' THEN 16
      WHEN '2X-Large' THEN 32
      WHEN '3X-Large' THEN 64
      WHEN '4X-Large' THEN 128
      ELSE 1
    END AS credits_by_warehouse_size    
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
where usage_day = $ref_date
),
wh_metering as (
select
    date(CONVERT_TIMEZONE('UTC', start_time)) as usage_day,
    warehouse_id,
    warehouse_name,
    sum(credits_used) as credits_used,
    sum(credits_used_compute) as credits_used_compute,
    sum(credits_used_cloud_services) as credits_used_cloud_services
from
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
where usage_day = $ref_date
group by 1,2,3
),
intermediate as (
select 
    b.usage_day,
    b.snowflake_query_id,
    b.database_name,
    b.query_text,
    b.role_name,
    b.query_result_rows_produced,
    b.user_name,
    b.warehouse_name,
    b.warehouse_size,
    b.end_time,
    b.start_time,
    b.end_time_pacific_time,
    b.start_time_pacific_time,    
    b.credits_by_warehouse_size,
    b.total_elapsed_time,
    whm.credits_used,
    whm.credits_used_compute,
    whm.credits_used_cloud_services,
    b.total_elapsed_time*credits_by_warehouse_size as weighted_tt_elapsed_time,    
    SUM(b.total_elapsed_time) over (partition by b.usage_day, b.warehouse_name) as elapsed_wh_day,
    SUM(b.total_elapsed_time) over (partition by b.usage_day) as elapsed_day
from 
    base b
join wh_metering whm using(warehouse_id, usage_day)
)
select
    usage_day,
    snowflake_query_id,
    database_name,
    query_text,
    role_name,
    query_result_rows_produced,
    user_name,
    warehouse_name,
    warehouse_size,
    end_time,
    start_time,
    credits_by_warehouse_size,
    total_elapsed_time,
    elapsed_wh_day,
    elapsed_day,
    credits_used,
    weighted_tt_elapsed_time,
    total_elapsed_time/elapsed_wh_day*credits_used*$credit_price as estimated_costs
from intermediate
