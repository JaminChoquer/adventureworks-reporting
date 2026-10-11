-- Conformité des habilitations sécurité en fin de mois.
-- Grain : salarié, formation requise, mois.
-- La matrice des formations requises est déduite des inscriptions : dans le système
-- source, un salarié n'est inscrit qu'aux formations exigées pour son poste.
with requirements as (
    select distinct business_entity_id as employee_id, course_code
    from {{ ref('stg_cx_ehs__training_records') }}
),

months as (
    select month_start, month_end
    from {{ ref('dim_month') }}
    where is_closed
),

valid_at_month_end as (
    select
        r.employee_id,
        r.course_code,
        m.month_start,
        max(t.valid_until) as valid_until
    from requirements as r
    cross join months as m
    left join {{ ref('stg_cx_ehs__training_records') }} as t
        on  t.business_entity_id = r.employee_id
        and t.course_code = r.course_code
        and t.result = 'Pass'
        and t.completed_on <= m.month_end
        and t.valid_until >= m.month_end
    group by 1, 2, 3
),

last_expiry as (
    select
        r.employee_id,
        r.course_code,
        m.month_start,
        max(t.valid_until) as last_valid_until
    from requirements as r
    cross join months as m
    left join {{ ref('stg_cx_ehs__training_records') }} as t
        on  t.business_entity_id = r.employee_id
        and t.course_code = r.course_code
        and t.result = 'Pass'
        and t.completed_on <= m.month_end
    group by 1, 2, 3
)

select
    concat(cast(v.employee_id as {{ dbt.type_string() }}), '|', v.course_code, '|',
           cast(v.month_start as {{ dbt.type_string() }}))           as compliance_key,
    v.employee_id,
    v.course_code,
    v.month_start,
    v.valid_until is not null                                          as is_compliant,
    v.valid_until,
    case when v.valid_until is null then {{ dbt.datediff('l.last_valid_until', 'm.month_end', 'day') }} end as days_overdue,
    v.valid_until is not null
        and {{ dbt.datediff('m.month_end', 'v.valid_until', 'day') }} <= 30 as expires_within_30_days
from valid_at_month_end as v
join months as m on m.month_start = v.month_start
left join last_expiry as l
    on l.employee_id = v.employee_id and l.course_code = v.course_code and l.month_start = v.month_start
