-- Tout lieu affiché sur une carte (État livré ou État d'un fournisseur) a des coordonnées.
select distinct g.state_province_id, g.state_province_name
from {{ ref('dim_geography') }} as g
where (g.latitude is null or g.longitude is null)
  and (
      g.state_province_id in (select state_province_id from {{ ref('mart_sales_monthly') }})
      or g.state_province_id in (select vendor_state_province_id from {{ ref('mart_purchasing_monthly') }})
  )
