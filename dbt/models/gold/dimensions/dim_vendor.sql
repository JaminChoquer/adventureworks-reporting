-- Fournisseurs.
select
    business_entity_id        as vendor_id,
    name                      as vendor_name,
    account_number,
    credit_rating,
    preferred_vendor_status   as is_preferred,
    active_flag               as is_active
from {{ ref('stg_aw_purchasing__vendor') }}
