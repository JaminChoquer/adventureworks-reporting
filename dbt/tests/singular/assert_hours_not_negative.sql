-- Aucune heure travaillée, planifiée ou d'absence ne doit être négative.
select *
from {{ ref('fct_hours_worked') }}
where worked_hours < 0 or scheduled_hours < 0 or overtime_hours < 0
   or absence_sickness_hours < 0 or absence_work_accident_hours < 0
