-- Audits qualité, environnement et 5S. Grain : un audit d'une zone.
select
    audit_id,
    audit_date,
    {{ month_start('audit_date') }}             as month_start,
    audit_type,
    location_id                                 as location_key,
    work_center                                 as work_center_code,
    auditor_business_entity_id                  as auditor_employee_id,
    auditor_organization,
    auditor_organization = 'External certification body' as is_external,
    score,
    findings_major,
    findings_minor,
    observations,
    findings_major + findings_minor             as findings_total
from {{ ref('stg_cx_quality__audits') }}
where {{ month_start('audit_date') }} <= date '{{ var("reporting_month") }}'
