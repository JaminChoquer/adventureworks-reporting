-- Silver : cx_ehs__training_records (données complémentaires), typée et renommée, sans règle métier.
select
    {{ txt('training_record_id') }}    as training_record_id,
    {{ to_int('business_entity_id') }} as business_entity_id,
    {{ txt('course_code') }}           as course_code,
    {{ to_date('completed_on') }}      as completed_on,
    {{ to_int('duration_hours') }}     as duration_hours,
    {{ to_int('score') }}              as score,
    {{ txt('result') }}                as result,
    {{ txt('provider') }}              as provider,
    {{ to_date('valid_until') }}       as valid_until,
    _source
from {{ source('bronze', 'cx_ehs__training_records') }}
