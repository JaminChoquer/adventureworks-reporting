-- Silver : cx_hr__temp_labor_monthly (données complémentaires), typée et renommée, sans règle métier.
select
    {{ to_month('month') }}    as month,
    {{ txt('work_center') }}   as work_center,
    {{ to_int('shift_id') }}   as shift_id,
    {{ txt('agency') }}        as agency,
    {{ to_num('temp_fte') }}   as temp_fte,
    {{ to_num('temp_hours') }} as temp_hours,
    {{ to_num('cost_usd') }}   as cost_usd,
    _source
from {{ source('bronze', 'cx_hr__temp_labor_monthly') }}
