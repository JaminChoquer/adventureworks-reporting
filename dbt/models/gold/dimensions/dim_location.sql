-- Zones physiques du site, avec leur position sur le plan schématique de l'usine.
-- La clé 0 regroupe les relevés du bâtiment et des services généraux.
select
    l.location_id                         as location_key,
    l.name                                as location_name,
    l.cost_rate,
    l.availability,
    m.work_center_code,
    p.x                                   as plan_x,
    p.y                                   as plan_y,
    p.width                               as plan_width,
    p.height                              as plan_height,
    p.flow_order
from {{ ref('stg_aw_production__location') }} as l
left join {{ ref('location_work_centers') }} as m on m.location_id = l.location_id
left join {{ ref('plant_layout') }} as p on p.location_id = l.location_id

union all

select
    0                                     as location_key,
    'Site-wide (buildings and utilities)' as location_name,
    null                                  as cost_rate,
    null                                  as availability,
    null                                  as work_center_code,
    null                                  as plan_x,
    null                                  as plan_y,
    null                                  as plan_width,
    null                                  as plan_height,
    null                                  as flow_order
