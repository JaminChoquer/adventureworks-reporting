-- Un accident avec arrêt a au moins un jour perdu ; les autres événements n'en ont aucun.
select event_id, event_type, days_lost
from {{ ref('fct_safety_events') }}
where (is_lost_time_injury and days_lost < 1)
   or (not is_lost_time_injury and days_lost > 0)
