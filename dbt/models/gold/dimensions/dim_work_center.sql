-- Ateliers de production et services support, axe commun QHSE, RH et production.
select
    work_center_code,
    work_center_name,
    area,
    main_location_id,
    sort_order
from {{ ref('work_centers') }}
