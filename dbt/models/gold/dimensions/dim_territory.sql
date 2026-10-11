-- Territoires de vente.
select
    t.territory_id,
    t.name                    as territory_name,
    t.country_region_code,
    c.name                    as country_name,
    t.territory_group
from {{ ref('stg_aw_sales__sales_territory') }} as t
left join {{ ref('stg_aw_person__country_region') }} as c on c.country_region_code = t.country_region_code
