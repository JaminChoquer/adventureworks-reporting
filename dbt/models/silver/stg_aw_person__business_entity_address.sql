-- Silver : aw_person__business_entity_address (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }}  as business_entity_id,
    {{ to_int('AddressID') }}         as address_id,
    {{ to_int('AddressTypeID') }}     as address_type_id,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_person__business_entity_address') }}
