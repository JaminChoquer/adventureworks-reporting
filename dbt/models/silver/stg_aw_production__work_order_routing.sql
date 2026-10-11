-- Silver : aw_production__work_order_routing (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('WorkOrderID') }}         as work_order_id,
    {{ to_int('ProductID') }}           as product_id,
    {{ to_int('OperationSequence') }}   as operation_sequence,
    {{ to_int('LocationID') }}          as location_id,
    {{ to_date('ScheduledStartDate') }} as scheduled_start_date,
    {{ to_date('ScheduledEndDate') }}   as scheduled_end_date,
    {{ to_date('ActualStartDate') }}    as actual_start_date,
    {{ to_date('ActualEndDate') }}      as actual_end_date,
    {{ to_num('ActualResourceHrs') }}   as actual_resource_hrs,
    {{ to_num('PlannedCost') }}         as planned_cost,
    {{ to_num('ActualCost') }}          as actual_cost,
    {{ to_date('ModifiedDate') }}       as modified_date,
    _source
from {{ source('bronze', 'aw_production__work_order_routing') }}
