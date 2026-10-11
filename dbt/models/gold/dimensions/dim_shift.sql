-- Équipes de travail (jour, soir, nuit).
select
    shift_id,
    name       as shift_name,
    start_time,
    end_time
from {{ ref('stg_aw_hr__shift') }}
