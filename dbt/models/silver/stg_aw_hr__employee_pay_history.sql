-- Silver : aw_hr__employee_pay_history (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }} as business_entity_id,
    {{ to_date('RateChangeDate') }}  as rate_change_date,
    {{ to_num('Rate') }}             as rate,
    {{ to_int('PayFrequency') }}     as pay_frequency,
    {{ to_date('ModifiedDate') }}    as modified_date,
    _source
from {{ source('bronze', 'aw_hr__employee_pay_history') }}
