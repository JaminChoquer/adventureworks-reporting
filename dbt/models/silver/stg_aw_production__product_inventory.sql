-- Silver : aw_production__product_inventory (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ProductID') }}     as product_id,
    {{ to_int('LocationID') }}    as location_id,
    {{ txt('Shelf') }}            as shelf,
    {{ to_int('Bin') }}           as bin,
    {{ to_int('Quantity') }}      as quantity,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__product_inventory') }}
