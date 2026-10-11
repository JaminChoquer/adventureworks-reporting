-- Heures travaillées et absences, salariés et intérimaires. Dénominateur des taux de
-- fréquence et de gravité. Grain : mois, atelier, équipe, type de travailleur.
with employees as (
    select
        month                                       as month_start,
        work_center                                 as work_center_code,
        shift_id,
        'Employee'                                  as worker_type,
        count(*)                                    as headcount,
        sum(scheduled_hours)                        as scheduled_hours,
        sum(overtime_hours)                         as overtime_hours,
        sum(absence_sickness_hours)                 as absence_sickness_hours,
        sum(absence_work_accident_hours)            as absence_work_accident_hours,
        sum(absence_vacation_hours)                 as absence_vacation_hours,
        sum(absence_other_hours)                    as absence_other_hours,
        sum(worked_hours)                           as worked_hours,
        cast(0 as {{ dbt.type_numeric() }})         as temp_labor_cost_usd
    from {{ ref('stg_cx_hr__timesheet_monthly') }}
    group by 1, 2, 3, 4
),

temps as (
    select
        month                                       as month_start,
        work_center                                 as work_center_code,
        shift_id,
        'Temporary'                                 as worker_type,
        sum(temp_fte)                               as headcount,
        sum(temp_hours)                             as scheduled_hours,
        cast(0 as {{ dbt.type_numeric() }})         as overtime_hours,
        cast(0 as {{ dbt.type_numeric() }})         as absence_sickness_hours,
        cast(0 as {{ dbt.type_numeric() }})         as absence_work_accident_hours,
        cast(0 as {{ dbt.type_numeric() }})         as absence_vacation_hours,
        cast(0 as {{ dbt.type_numeric() }})         as absence_other_hours,
        sum(temp_hours)                             as worked_hours,
        sum(cost_usd)                               as temp_labor_cost_usd
    from {{ ref('stg_cx_hr__temp_labor_monthly') }}
    group by 1, 2, 3, 4
),

unioned as (
    select * from employees
    union all
    select * from temps
)

select
    concat(cast(month_start as {{ dbt.type_string() }}), '|', work_center_code, '|',
           cast(shift_id as {{ dbt.type_string() }}), '|', worker_type) as hours_key,
    *
from unioned
where month_start <= date '{{ var("reporting_month") }}'
