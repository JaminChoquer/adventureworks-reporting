-- Temps de travail, absences, formation et coût par salarié et par mois.
-- Grain : salarié, mois.
with training as (
    select employee_id, month_start, sum(duration_hours) as training_hours
    from {{ ref('fct_training_sessions') }}
    group by 1, 2
)

select
    concat(cast(t.business_entity_id as {{ dbt.type_string() }}), '|',
           cast(t.month as {{ dbt.type_string() }}))                     as hr_key,
    t.business_entity_id                                                 as employee_id,
    t.month                                                              as month_start,
    t.department_id,
    t.shift_id,
    t.work_center                                                        as work_center_code,
    t.scheduled_hours,
    t.overtime_hours,
    t.absence_sickness_hours,
    t.absence_work_accident_hours,
    t.absence_vacation_hours,
    t.absence_other_hours,
    -- Absentéisme : absences subies, hors congés planifiés
    t.absence_sickness_hours + t.absence_work_accident_hours + t.absence_other_hours as absence_hours,
    t.worked_hours,
    coalesce(tr.training_hours, 0)                                       as training_hours,
    p.payroll_cost_usd
from {{ ref('stg_cx_hr__timesheet_monthly') }} as t
left join training as tr on tr.employee_id = t.business_entity_id and tr.month_start = t.month
left join {{ ref('fct_payroll_monthly') }} as p on p.employee_id = t.business_entity_id and p.month_start = t.month
where t.month <= date '{{ var("reporting_month") }}'
