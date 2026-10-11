-- Silver : cx_ehs__training_catalog (données complémentaires), typée et renommée, sans règle métier.
select
    {{ txt('course_code') }}        as course_code,
    {{ txt('course_title') }}       as course_title,
    {{ txt('category') }}           as category,
    {{ to_int('duration_hours') }}  as duration_hours,
    {{ to_int('validity_months') }} as validity_months,
    {{ txt('required_for') }}       as required_for,
    _source
from {{ source('bronze', 'cx_ehs__training_catalog') }}
