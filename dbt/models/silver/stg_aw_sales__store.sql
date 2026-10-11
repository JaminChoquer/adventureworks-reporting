-- Silver : aw_sales__store (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }}  as business_entity_id,
    {{ txt('Name') }}                 as name,
    {{ to_int('SalesPersonID') }}     as sales_person_id,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_sales__store') }}
