-- Conformité des habilitations par mois, atelier, équipe et formation.
select
    c.month_start,
    e.work_center_code,
    e.shift_id,
    c.course_code,
    t.course_title,
    t.course_category,
    count(*)                                                        as required,
    sum(case when c.is_compliant then 1 else 0 end)                 as compliant,
    sum(case when c.expires_within_30_days then 1 else 0 end)       as expiring_within_30_days
from {{ ref('fct_training_compliance') }} as c
left join {{ ref('dim_employee') }} as e on e.employee_id = c.employee_id
left join {{ ref('dim_training_course') }} as t on t.course_code = c.course_code
group by 1, 2, 3, 4, 5, 6
