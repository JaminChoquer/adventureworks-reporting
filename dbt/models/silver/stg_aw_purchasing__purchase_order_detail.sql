-- Silver : aw_purchasing__purchase_order_detail (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('PurchaseOrderID') }}       as purchase_order_id,
    {{ to_int('PurchaseOrderDetailID') }} as purchase_order_detail_id,
    {{ to_date('DueDate') }}              as due_date,
    {{ to_int('OrderQty') }}              as order_qty,
    {{ to_int('ProductID') }}             as product_id,
    {{ to_num('UnitPrice') }}             as unit_price,
    {{ to_num('LineTotal') }}             as line_total,
    {{ to_num('ReceivedQty') }}           as received_qty,
    {{ to_num('RejectedQty') }}           as rejected_qty,
    {{ to_num('StockedQty') }}            as stocked_qty,
    {{ to_datetime('ModifiedDate') }}     as modified_date,
    _source
from {{ source('bronze', 'aw_purchasing__purchase_order_detail') }}
