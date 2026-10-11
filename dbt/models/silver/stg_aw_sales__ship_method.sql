-- Silver : aw_sales__ship_method (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ShipMethodID') }}  as ship_method_id,
    {{ txt('Name') }}             as name,
    {{ to_num('ShipBase') }}      as ship_base,
    {{ to_num('ShipRate') }}      as ship_rate,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_sales__ship_method') }}
