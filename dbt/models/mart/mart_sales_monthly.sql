-- Ventes agrégées par mois et par axe de filtre du dashboard.
-- Les commandes sont comptées dans chaque combinaison : leur total sur plusieurs
-- combinaisons peut dépasser le nombre réel de commandes (utiliser kpi_monthly pour le total).
select
    s.month_start,
    g.country_region_code,
    g.country_name,
    s.ship_to_state_province_id                         as state_province_id,
    g.state_province_name,
    s.territory_id,
    t.territory_name,
    t.territory_group,
    s.sales_channel,
    p.category_name,
    p.subcategory_name,
    c.customer_type,
    sum(s.gross_sales_usd)                              as gross_sales_usd,
    sum(s.discount_usd)                                 as discount_usd,
    sum(s.net_sales_usd)                                as net_sales_usd,
    sum(s.cost_of_sales_usd)                            as cost_of_sales_usd,
    sum(s.gross_margin_usd)                             as gross_margin_usd,
    sum(s.freight_billed_usd)                           as freight_billed_usd,
    sum(s.order_qty)                                    as units,
    count(*)                                            as order_lines,
    count(distinct s.sales_order_id)                    as orders
from {{ ref('fct_sales_lines') }} as s
left join {{ ref('dim_geography') }} as g on g.state_province_id = s.ship_to_state_province_id
left join {{ ref('dim_territory') }} as t on t.territory_id = s.territory_id
left join {{ ref('dim_product') }} as p on p.product_id = s.product_id
left join {{ ref('dim_customer') }} as c on c.customer_id = s.customer_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
