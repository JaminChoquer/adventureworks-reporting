-- Silver : aw_purchasing__product_vendor (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ProductID') }}         as product_id,
    {{ to_int('BusinessEntityID') }}  as business_entity_id,
    {{ to_int('AverageLeadTime') }}   as average_lead_time,
    {{ to_num('StandardPrice') }}     as standard_price,
    {{ to_num('LastReceiptCost') }}   as last_receipt_cost,
    {{ to_date('LastReceiptDate') }}  as last_receipt_date,
    {{ to_int('MinOrderQty') }}       as min_order_qty,
    {{ to_int('MaxOrderQty') }}       as max_order_qty,
    {{ to_int('OnOrderQty') }}        as on_order_qty,
    {{ txt('UnitMeasureCode') }}      as unit_measure_code,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_purchasing__product_vendor') }}
