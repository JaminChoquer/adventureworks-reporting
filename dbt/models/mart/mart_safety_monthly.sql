-- Événements sécurité agrégés par mois et par axe de filtre. Les heures travaillées,
-- dénominateur des taux, sont dans mart_hours_monthly au même grain atelier, équipe et
-- type de travailleur.
select
    month_start,
    work_center_code,
    location_key,
    shift_id,
    worker_type,
    event_type,
    severity_potential,
    root_cause_category,
    coalesce(injury_nature, 'Not an injury')            as injury_nature,
    count(*)                                            as events,
    sum(case when is_lost_time_injury then 1 else 0 end) as lost_time_injuries,
    sum(case when is_recordable then 1 else 0 end)      as recordables,
    sum(days_lost)                                      as days_lost,
    sum(days_restricted)                                as days_restricted,
    sum(case when status != 'Closed' then 1 else 0 end) as open_events
from {{ ref('fct_safety_events') }}
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
