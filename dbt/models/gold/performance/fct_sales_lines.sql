-- Lignes de vente valorisées. Le chiffre d'affaires est rattaché au mois d'expédition ;
-- le coût des ventes utilise le coût standard en vigueur à cette date (à défaut, le coût
-- standard actuel du produit). Grain : une ligne de commande client.
with lines as (
    select
        d.sales_order_detail_id,
        d.sales_order_id,
        d.product_id,
        d.special_offer_id,
        d.order_qty,
        d.unit_price,
        d.unit_price_discount,
        d.line_total,
        h.order_date,
        h.due_date,
        h.ship_date,
        h.customer_id,
        h.sales_person_id,
        h.territory_id,
        h.ship_method_id,
        h.ship_to_address_id,
        h.online_order_flag,
        h.sub_total,
        h.freight
    from {{ ref('stg_aw_sales__sales_order_detail') }} as d
    join {{ ref('stg_aw_sales__sales_order_header') }} as h on h.sales_order_id = d.sales_order_id
),

costed as (
    select
        l.*,
        coalesce(c.standard_cost, p.standard_cost) as unit_standard_cost,
        c.standard_cost is null                    as is_cost_fallback
    from lines as l
    left join {{ ref('stg_aw_production__product_cost_history') }} as c
        on  c.product_id = l.product_id
        and l.ship_date >= c.start_date
        and (c.end_date is null or l.ship_date < c.end_date)
    left join {{ ref('stg_aw_production__product') }} as p on p.product_id = l.product_id
),

located as (
    select c.*, a.state_province_id as ship_to_state_province_id
    from costed as c
    left join {{ ref('stg_aw_person__address') }} as a on a.address_id = c.ship_to_address_id
)

select
    sales_order_detail_id,
    sales_order_id,
    order_date,
    ship_date,
    {{ month_start('ship_date') }}                                     as month_start,
    customer_id,
    sales_person_id                                                    as sales_person_employee_id,
    territory_id,
    ship_to_state_province_id,
    product_id,
    special_offer_id,
    ship_method_id,
    case when online_order_flag then 'Online' else 'Reseller' end      as sales_channel,
    {{ dbt.datediff('order_date', 'ship_date', 'day') }}               as days_to_ship,
    order_qty,
    unit_price,
    unit_price_discount,
    order_qty * unit_price                                             as gross_sales_usd,
    order_qty * unit_price - line_total                                as discount_usd,
    line_total                                                         as net_sales_usd,
    unit_standard_cost,
    is_cost_fallback,
    order_qty * unit_standard_cost                                     as cost_of_sales_usd,
    line_total - order_qty * unit_standard_cost                        as gross_margin_usd,
    case when sub_total > 0 then freight * line_total / sub_total else 0 end as freight_billed_usd
from located
where {{ month_start('ship_date') }} between date '{{ var("calendar_start") }}' and date '{{ var("reporting_month") }}'
