-- Salariés avec leur affectation actuelle, leur atelier et des tranches d'âge et d'ancienneté
-- calculées au dernier mois clôturé.
with current_assignment as (
    select business_entity_id, department_id, shift_id
    from {{ ref('stg_aw_hr__employee_department_history') }}
    where end_date is null
),

latest_rate as (
    select business_entity_id, rate, pay_frequency
    from (
        select
            business_entity_id, rate, pay_frequency,
            row_number() over (partition by business_entity_id order by rate_change_date desc) as rn
        from {{ ref('stg_aw_hr__employee_pay_history') }}
    ) as ranked
    where rn = 1
),

base as (
    select
        e.business_entity_id                                           as employee_id,
        concat(p.first_name, ' ', p.last_name)                         as full_name,
        e.job_title,
        e.gender,
        e.marital_status,
        e.birth_date,
        e.hire_date,
        e.salaried_flag                                                as is_salaried,
        e.organization_level,
        d.department_id,
        d.name                                                         as department_name,
        d.group_name                                                   as department_group,
        a.shift_id,
        case
            when e.job_title like '%- WC%' then substr(e.job_title, length(e.job_title) - 3, 4)
            when a.department_id = 15 then 'LOG'
            when a.department_id = 14 then 'MNT'
            when a.department_id in (12, 13) then 'QA'
            else 'OFF'
        end                                                            as work_center_code,
        r.rate                                                         as current_hourly_rate,
        {{ dbt.datediff('e.birth_date', "date '" ~ var('reporting_month') ~ "'", 'day') }} / 365.25 as age_years,
        {{ dbt.datediff('e.hire_date', "date '" ~ var('reporting_month') ~ "'", 'day') }} / 365.25  as seniority_years
    from {{ ref('stg_aw_hr__employee') }} as e
    left join {{ ref('stg_aw_person__person') }} as p on p.business_entity_id = e.business_entity_id
    left join current_assignment as a on a.business_entity_id = e.business_entity_id
    left join {{ ref('stg_aw_hr__department') }} as d on d.department_id = a.department_id
    left join latest_rate as r on r.business_entity_id = e.business_entity_id
)

select
    *,
    case
        when age_years < 30 then 'Under 30'
        when age_years < 40 then '30-39'
        when age_years < 50 then '40-49'
        else '50 and over'
    end as age_band,
    case
        when seniority_years < 10 then 'Under 10 years'
        when seniority_years < 15 then '10-14 years'
        else '15 years and over'
    end as seniority_band
from base
