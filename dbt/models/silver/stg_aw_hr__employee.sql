-- Silver : aw_hr__employee (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }}  as business_entity_id,
    {{ txt('OrganizationNode') }}     as organization_node,
    {{ to_int('OrganizationLevel') }} as organization_level,
    {{ txt('JobTitle') }}             as job_title,
    {{ to_date('BirthDate') }}        as birth_date,
    {{ txt('MaritalStatus') }}        as marital_status,
    {{ txt('Gender') }}               as gender,
    {{ to_date('HireDate') }}         as hire_date,
    {{ to_bool('SalariedFlag') }}     as salaried_flag,
    {{ to_int('VacationHours') }}     as vacation_hours,
    {{ to_int('SickLeaveHours') }}    as sick_leave_hours,
    {{ to_bool('CurrentFlag') }}      as current_flag,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_hr__employee') }}
