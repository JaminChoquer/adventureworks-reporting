-- Silver : aw_person__person (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }}  as business_entity_id,
    {{ txt('PersonType') }}           as person_type,
    {{ to_bool('NameStyle') }}        as name_style,
    {{ txt('Title') }}                as title,
    {{ txt('FirstName') }}            as first_name,
    {{ txt('MiddleName') }}           as middle_name,
    {{ txt('LastName') }}             as last_name,
    {{ txt('Suffix') }}               as suffix,
    {{ to_int('EmailPromotion') }}    as email_promotion,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_person__person') }}
