-- Silver : aw_purchasing__purchase_order_header (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('PurchaseOrderID') }}   as purchase_order_id,
    {{ to_int('RevisionNumber') }}    as revision_number,
    {{ to_int('Status') }}            as status,
    {{ to_int('EmployeeID') }}        as employee_id,
    {{ to_int('VendorID') }}          as vendor_id,
    {{ to_int('ShipMethodID') }}      as ship_method_id,
    {{ to_date('OrderDate') }}        as order_date,
    {{ to_date('ShipDate') }}         as ship_date,
    {{ to_num('SubTotal') }}          as sub_total,
    {{ to_num('TaxAmt') }}            as tax_amt,
    {{ to_num('Freight') }}           as freight,
    {{ to_num('TotalDue') }}          as total_due,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_purchasing__purchase_order_header') }}
