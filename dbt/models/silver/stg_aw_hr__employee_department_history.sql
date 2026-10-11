-- Silver : aw_hr__employee_department_history (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }} as business_entity_id,
    {{ to_int('DepartmentID') }}     as department_id,
    {{ to_int('ShiftID') }}          as shift_id,
    {{ to_date('StartDate') }}       as start_date,
    {{ to_date('EndDate') }}         as end_date,
    {{ to_date('ModifiedDate') }}    as modified_date,
    _source
from {{ source('bronze', 'aw_hr__employee_department_history') }}
