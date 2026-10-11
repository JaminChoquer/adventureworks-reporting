-- Silver : aw_production__work_order (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('WorkOrderID') }}   as work_order_id,
    {{ to_int('ProductID') }}     as product_id,
    {{ to_int('OrderQty') }}      as order_qty,
    {{ to_int('StockedQty') }}    as stocked_qty,
    {{ to_int('ScrappedQty') }}   as scrapped_qty,
    {{ to_date('StartDate') }}    as start_date,
    {{ to_date('EndDate') }}      as end_date,
    {{ to_date('DueDate') }}      as due_date,
    {{ to_int('ScrapReasonID') }} as scrap_reason_id,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__work_order') }}
