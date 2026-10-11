-- Silver : aw_person__address (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('AddressID') }}         as address_id,
    {{ txt('City') }}                 as city,
    {{ to_int('StateProvinceID') }}   as state_province_id,
    {{ txt('PostalCode') }}           as postal_code,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_person__address') }}
