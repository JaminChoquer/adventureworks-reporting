-- Achats agrégés par mois, fournisseur (localisé) et catégorie de produit.
select
    l.month_start,
    l.vendor_id,
    v.vendor_name,
    v.is_preferred,
    v.state_province_id                                 as vendor_state_province_id,
    g.state_province_code                               as vendor_state_code,
    g.state_province_name                               as vendor_state_name,
    p.category_name,
    p.subcategory_name,
    count(*)                                            as purchase_lines,
    sum(l.order_qty)                                    as ordered_qty,
    sum(l.received_qty)                                 as received_qty,
    sum(l.rejected_qty)                                 as rejected_qty,
    sum(l.received_value_usd)                           as received_value_usd,
    sum(l.rejected_value_usd)                           as rejected_value_usd,
    sum(l.lead_time_days)                               as lead_time_days_total
from {{ ref('fct_purchase_lines') }} as l
left join {{ ref('dim_vendor') }} as v on v.vendor_id = l.vendor_id
left join {{ ref('dim_geography') }} as g on g.state_province_id = v.state_province_id
left join {{ ref('dim_product') }} as p on p.product_id = l.product_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
