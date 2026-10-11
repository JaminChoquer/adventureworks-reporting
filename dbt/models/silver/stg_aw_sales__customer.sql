-- Silver : aw_sales__customer (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('CustomerID') }}        as customer_id,
    {{ to_int('PersonID') }}          as person_id,
    {{ to_int('StoreID') }}           as store_id,
    {{ to_int('TerritoryID') }}       as territory_id,
    {{ txt('AccountNumber') }}        as account_number,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_sales__customer') }}
