-- Silver : aw_hr__shift (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ShiftID') }}       as shift_id,
    {{ txt('Name') }}             as name,
    {{ txt('StartTime') }}        as start_time,
    {{ txt('EndTime') }}          as end_time,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_hr__shift') }}
