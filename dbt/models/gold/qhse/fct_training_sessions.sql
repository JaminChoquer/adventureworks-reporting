-- Sessions de formation suivies pendant la période. Grain : une session.
select
    training_record_id                         as session_id,
    business_entity_id                         as employee_id,
    course_code,
    completed_on                               as session_date,
    {{ month_start('completed_on') }}          as month_start,
    duration_hours,
    score,
    result,
    result = 'Pass'                            as is_passed,
    provider,
    valid_until
from {{ ref('stg_cx_ehs__training_records') }}
where completed_on >= date '{{ var("calendar_start") }}'
  and {{ month_start('completed_on') }} <= date '{{ var("reporting_month") }}'
