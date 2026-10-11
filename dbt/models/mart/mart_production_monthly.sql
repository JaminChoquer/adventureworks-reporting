-- Production agrégée par mois, catégorie de produit et motif de rebut.
select
    o.month_start,
    p.category_name,
    p.subcategory_name,
    coalesce(o.scrap_reason, 'No scrap')                as scrap_reason,
    count(*)                                            as work_orders,
    sum(case when o.is_late then 1 else 0 end)          as late_work_orders,
    sum(o.days_late)                                    as days_late,
    sum(o.order_qty)                                    as ordered_qty,
    sum(o.scrapped_qty)                                 as scrapped_qty,
    sum(o.scrap_cost_usd)                               as scrap_cost_usd,
    sum(o.actual_resource_hours)                        as resource_hours,
    sum(o.lead_time_days)                               as lead_time_days_total
from {{ ref('fct_production_orders') }} as o
left join {{ ref('dim_product') }} as p on p.product_id = o.product_id
group by 1, 2, 3, 4
