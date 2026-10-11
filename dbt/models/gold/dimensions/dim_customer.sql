-- Clients : revendeurs (magasins) ou particuliers. Les noms des particuliers ne sont pas
-- repris, inutiles au reporting.
select
    c.customer_id,
    case when c.store_id is not null then 'Reseller' else 'Individual' end as customer_type,
    s.name                     as store_name,
    c.territory_id,
    c.account_number
from {{ ref('stg_aw_sales__customer') }} as c
left join {{ ref('stg_aw_sales__store') }} as s on s.business_entity_id = c.store_id
