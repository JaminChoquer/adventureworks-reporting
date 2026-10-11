-- Registre des événements santé-sécurité. Grain : un événement.
select
    incident_id                                                         as event_id,
    event_type,
    cast(occurred_at as date)                                           as event_date,
    {{ month_start('cast(occurred_at as date)') }}                      as month_start,
    occurred_at,
    reported_at,
    {{ dbt.datediff('occurred_at', 'reported_at', 'hour') }}            as reporting_delay_hours,
    coalesce(location_id, 0)                                            as location_key,
    work_center                                                         as work_center_code,
    shift_id,
    worker_type,
    injured_business_entity_id                                          as injured_employee_id,
    reported_by_business_entity_id                                      as reporter_employee_id,
    event_type in ('Lost time injury', 'Medical treatment', 'First aid') as is_injury,
    event_type = 'Lost time injury'                                     as is_lost_time_injury,
    -- Recordable au sens OSHA : accident avec arrêt ou soins médicaux
    event_type in ('Lost time injury', 'Medical treatment')             as is_recordable,
    event_type in ('Near miss', 'Hazardous situation')                  as is_proactive_report,
    injury_nature,
    body_part,
    activity,
    root_cause_category,
    severity_potential,
    coalesce(days_lost, 0)                                              as days_lost,
    coalesce(days_restricted, 0)                                        as days_restricted,
    status,
    closed_at,
    {{ dbt.datediff('reported_at', 'closed_at', 'day') }}               as days_to_close
from {{ ref('stg_cx_ehs__incidents') }}
where {{ month_start('cast(occurred_at as date)') }} <= date '{{ var("reporting_month") }}'
