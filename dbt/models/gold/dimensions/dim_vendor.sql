-- Fournisseurs, localisés par l'État de leur adresse principale.
with addresses as (
    select
        b.business_entity_id,
        a.state_province_id,
        a.city,
        row_number() over (partition by b.business_entity_id order by b.address_type_id) as rn
    from {{ ref('stg_aw_person__business_entity_address') }} as b
    join {{ ref('stg_aw_person__address') }} as a on a.address_id = b.address_id
)

select
    v.business_entity_id        as vendor_id,
    v.name                      as vendor_name,
    v.account_number,
    v.credit_rating,
    v.preferred_vendor_status   as is_preferred,
    v.active_flag               as is_active,
    a.city,
    a.state_province_id
from {{ ref('stg_aw_purchasing__vendor') }} as v
left join addresses as a on a.business_entity_id = v.business_entity_id and a.rn = 1
