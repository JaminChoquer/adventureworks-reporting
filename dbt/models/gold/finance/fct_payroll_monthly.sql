-- Masse salariale mensuelle estimée. Grain : salarié, mois.
-- Heures payées = heures planifiées (absences rémunérées comprises) + heures
-- supplémentaires majorées de 50 %, au taux horaire en vigueur en fin de mois.
with rates as (
    select
        t.month,
        t.business_entity_id,
        p.rate,
        row_number() over (
            partition by t.month, t.business_entity_id
            order by p.rate_change_date desc
        ) as rn
    from {{ ref('stg_cx_hr__timesheet_monthly') }} as t
    join {{ ref('stg_aw_hr__employee_pay_history') }} as p
        on  p.business_entity_id = t.business_entity_id
        and p.rate_change_date <= {{ dbt.last_day('t.month', 'month') }}
)

select
    concat(cast(t.business_entity_id as {{ dbt.type_string() }}), '|',
           cast(t.month as {{ dbt.type_string() }}))                  as payroll_key,
    t.business_entity_id                                              as employee_id,
    t.month                                                           as month_start,
    t.work_center                                                     as work_center_code,
    t.scheduled_hours,
    t.overtime_hours,
    t.scheduled_hours + 1.5 * t.overtime_hours                        as paid_hours,
    r.rate                                                            as hourly_rate_usd,
    (t.scheduled_hours + 1.5 * t.overtime_hours) * r.rate             as payroll_cost_usd,
    t.overtime_hours * 1.5 * r.rate                                   as overtime_cost_usd
from {{ ref('stg_cx_hr__timesheet_monthly') }} as t
left join rates as r
    on r.month = t.month and r.business_entity_id = t.business_entity_id and r.rn = 1
where t.month <= date '{{ var("reporting_month") }}'
