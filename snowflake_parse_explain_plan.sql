-- The SQL statement can be variabilized but there's a size limit https://docs.snowflake.com/en/sql-reference/session-variables.html#initializing-variables
select SYSTEM$EXPLAIN_PLAN_JSON(
        '
           -- Write your SQL  --- 
           -- escape quotes with \ ---            
        '
) as explain_plan;
    
with plan as (
    select PARSE_JSON($1) as src from table(result_scan(last_query_id()))
)

select 
    src:GlobalStats.partitionsTotal::number as partitions_total,
    src:GlobalStats.partitionsAssigned::number as partitions_assigned,
    src:GlobalStats.bytesAssigned::number as bytes_assigned,
    z.value:alias::string as alias,   
    z.value:bytesAssigned::string as bytes_assigned,   
    z.value:partitionsTotal::number as partitions_total,
    z.value:partitionsAssigned::number as partitions_assigned,    
    z.value:expressions::array as expressions,
    z.value:id::number as id,
    z.value:objects::array as objs,
    z.value:operation::string as operation,
    z.value:parent::number as parent
from 
    plan p,
    LATERAL FLATTEN(INPUT => p.src:Operations[0], RECURSIVE => TRUE, mode => 'ARRAY')  as z
  order by id desc
