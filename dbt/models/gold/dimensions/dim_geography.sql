-- États et provinces avec leur pays, leur territoire de vente et leurs coordonnées
-- (centroïdes publics, jeu dr5hn/countries-states-cities-database, licence ODbL).
select
    sp.state_province_id,
    sp.state_province_code,
    sp.name                       as state_province_name,
    sp.country_region_code,
    c.country_name,
    c.iso3                        as country_iso3,
    c.iso_numeric                 as country_iso_numeric,
    sp.territory_id,
    g.latitude,
    g.longitude,
    c.latitude                    as country_latitude,
    c.longitude                   as country_longitude
from {{ ref('stg_aw_person__state_province') }} as sp
left join {{ ref('geo_state_provinces') }} as g on g.state_province_id = sp.state_province_id
left join {{ ref('geo_countries') }} as c on c.country_region_code = sp.country_region_code
