-- Silver : cx_quality__audits (données complémentaires), typée et renommée, sans règle métier.
select
    {{ txt('audit_id') }}                      as audit_id,
    {{ to_date('audit_date') }}                as audit_date,
    {{ txt('audit_type') }}                    as audit_type,
    {{ to_int('location_id') }}                as location_id,
    {{ txt('work_center') }}                   as work_center,
    {{ to_int('auditor_business_entity_id') }} as auditor_business_entity_id,
    {{ txt('auditor_organization') }}          as auditor_organization,
    {{ to_num('score') }}                      as score,
    {{ to_int('findings_major') }}             as findings_major,
    {{ to_int('findings_minor') }}             as findings_minor,
    {{ to_int('observations') }}               as observations,
    _source
from {{ source('bronze', 'cx_quality__audits') }}
