-- Silver : aw_production__location (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('LocationID') }}    as location_id,
    {{ txt('Name') }}             as name,
    {{ to_num('CostRate') }}      as cost_rate,
    {{ to_num('Availability') }}  as availability,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__location') }}
