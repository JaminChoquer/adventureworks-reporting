-- Silver : cx_hr__timesheet_monthly (données complémentaires), typée et renommée, sans règle métier.
select
    {{ to_month('month') }}                     as month,
    {{ to_int('business_entity_id') }}          as business_entity_id,
    {{ to_int('department_id') }}               as department_id,
    {{ to_int('shift_id') }}                    as shift_id,
    {{ txt('work_center') }}                    as work_center,
    {{ to_num('scheduled_hours') }}             as scheduled_hours,
    {{ to_num('overtime_hours') }}              as overtime_hours,
    {{ to_num('absence_sickness_hours') }}      as absence_sickness_hours,
    {{ to_num('absence_work_accident_hours') }} as absence_work_accident_hours,
    {{ to_num('absence_vacation_hours') }}      as absence_vacation_hours,
    {{ to_num('absence_other_hours') }}         as absence_other_hours,
    {{ to_num('worked_hours') }}                as worked_hours,
    _source
from {{ source('bronze', 'cx_hr__timesheet_monthly') }}
