-- Silver : aw_person__state_province (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('StateProvinceID') }}          as state_province_id,
    {{ txt('StateProvinceCode') }}           as state_province_code,
    {{ txt('CountryRegionCode') }}           as country_region_code,
    {{ to_bool('IsOnlyStateProvinceFlag') }} as is_only_state_province_flag,
    {{ txt('Name') }}                        as name,
    {{ to_int('TerritoryID') }}              as territory_id,
    {{ to_datetime('ModifiedDate') }}        as modified_date,
    _source
from {{ source('bronze', 'aw_person__state_province') }}
