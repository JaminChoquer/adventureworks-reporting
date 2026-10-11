-- Silver : cx_environment__monthly_readings (données complémentaires), typée et renommée, sans règle métier.
select
    {{ to_month('month') }}     as month,
    {{ to_int('location_id') }} as location_id,
    {{ txt('indicator') }}      as indicator,
    {{ to_num('value') }}       as value,
    {{ txt('unit') }}           as unit,
    {{ txt('source') }}         as source,
    _source
from {{ source('bronze', 'cx_environment__monthly_readings') }}
