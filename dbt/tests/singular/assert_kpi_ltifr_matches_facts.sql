-- Le taux de fréquence sur 12 mois du dernier mois clôturé se recalcule à l'identique
-- depuis les tables de faits.
with last_month as (
    select month_start from {{ ref('dim_month') }} where is_reporting_month
),
window_months as (
    select m.month_start
    from {{ ref('dim_month') }} as m cross join last_month as l
    where m.month_start > {{ dbt.dateadd('month', -12, 'l.month_start') }} and m.month_start <= l.month_start
),
facts as (
    select
        (select count(*) from {{ ref('fct_safety_events') }}
          where is_lost_time_injury and month_start in (select month_start from window_months)) * 1000000.0
        / (select sum(worked_hours) from {{ ref('fct_hours_worked') }}
          where month_start in (select month_start from window_months)) as ltifr
),
kpi as (
    select rolling_12m_value as ltifr
    from {{ ref('kpi_monthly') }}
    where kpi_code = 'LTIFR' and month_start = (select month_start from last_month)
)
select facts.ltifr as from_facts, kpi.ltifr as from_kpi
from facts cross join kpi
where abs(facts.ltifr - kpi.ltifr) > 0.0001
