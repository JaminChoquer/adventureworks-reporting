-- RH agrégées par mois et par axe de filtre (service, atelier, équipe, sexe, âge, ancienneté).
select
    h.month_start,
    e.department_name,
    e.department_group,
    h.work_center_code,
    h.shift_id,
    e.gender,
    e.age_band,
    e.seniority_band,
    e.is_salaried,
    count(*)                                            as headcount,
    sum(h.scheduled_hours)                              as scheduled_hours,
    sum(h.overtime_hours)                               as overtime_hours,
    sum(h.absence_sickness_hours)                       as absence_sickness_hours,
    sum(h.absence_work_accident_hours)                  as absence_work_accident_hours,
    sum(h.absence_vacation_hours)                       as absence_vacation_hours,
    sum(h.absence_other_hours)                          as absence_other_hours,
    sum(h.absence_hours)                                as absence_hours,
    sum(h.worked_hours)                                 as worked_hours,
    sum(h.training_hours)                               as training_hours,
    sum(h.payroll_cost_usd)                             as payroll_cost_usd
from {{ ref('fct_hr_monthly') }} as h
left join {{ ref('dim_employee') }} as e on e.employee_id = h.employee_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
