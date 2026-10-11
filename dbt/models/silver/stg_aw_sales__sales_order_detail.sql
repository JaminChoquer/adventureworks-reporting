-- Silver : aw_sales__sales_order_detail (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('SalesOrderID') }}       as sales_order_id,
    {{ to_int('SalesOrderDetailID') }} as sales_order_detail_id,
    {{ txt('CarrierTrackingNumber') }} as carrier_tracking_number,
    {{ to_int('OrderQty') }}           as order_qty,
    {{ to_int('ProductID') }}          as product_id,
    {{ to_int('SpecialOfferID') }}     as special_offer_id,
    {{ to_num('UnitPrice') }}          as unit_price,
    {{ to_num('UnitPriceDiscount') }}  as unit_price_discount,
    {{ to_num('LineTotal') }}          as line_total,
    {{ to_date('ModifiedDate') }}      as modified_date,
    _source
from {{ source('bronze', 'aw_sales__sales_order_detail') }}
