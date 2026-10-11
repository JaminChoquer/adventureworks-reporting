-- Silver : aw_hr__department (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('DepartmentID') }}  as department_id,
    {{ txt('Name') }}             as name,
    {{ txt('GroupName') }}        as group_name,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_hr__department') }}
