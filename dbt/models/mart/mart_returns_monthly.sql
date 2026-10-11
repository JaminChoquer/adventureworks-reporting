-- Retours clients agrégés par mois, motif, catégorie de produit et pays.
select
    r.month_start,
    r.return_reason,
    r.is_quality_defect,
    coalesce(r.defect_origin_work_center_code, 'Unassigned') as defect_origin_work_center_code,
    p.category_name,
    p.subcategory_name,
    g.country_region_code,
    g.country_name,
    count(*)                                            as returns,
    sum(r.qty_returned)                                 as units_returned,
    sum(r.refund_amount_usd)                            as refund_amount_usd,
    sum(r.handling_cost_usd)                            as handling_cost_usd,
    sum(r.total_cost_usd)                               as total_cost_usd
from {{ ref('fct_customer_returns') }} as r
left join {{ ref('dim_product') }} as p on p.product_id = r.product_id
left join {{ ref('fct_sales_lines') }} as s on s.sales_order_detail_id = r.sales_order_detail_id
left join {{ ref('dim_geography') }} as g on g.state_province_id = s.ship_to_state_province_id
group by 1, 2, 3, 4, 5, 6, 7, 8
