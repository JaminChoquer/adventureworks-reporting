-- Heures travaillées par mois, atelier, équipe et type de travailleur.
select
    month_start,
    work_center_code,
    shift_id,
    worker_type,
    headcount,
    scheduled_hours,
    overtime_hours,
    worked_hours,
    temp_labor_cost_usd
from {{ ref('fct_hours_worked') }}
