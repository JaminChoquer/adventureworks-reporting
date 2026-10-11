-- Silver : aw_person__country_region (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ txt('CountryRegionCode') }} as country_region_code,
    {{ txt('Name') }}              as name,
    {{ to_date('ModifiedDate') }}  as modified_date,
    _source
from {{ source('bronze', 'aw_person__country_region') }}
