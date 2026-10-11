-- Retours clients (RMA), rattachés à la ligne de commande d'origine.
-- Grain : un retour.
select
    r.rma_id,
    r.return_date,
    {{ month_start('r.return_date') }}                                  as month_start,
    r.sales_order_id,
    r.sales_order_detail_id,
    r.product_id,
    h.territory_id,
    h.ship_date,
    {{ dbt.datediff('h.ship_date', 'r.return_date', 'day') }}           as days_since_shipment,
    r.qty_returned,
    r.return_reason,
    r.return_reason in ('Paint defect', 'Weld crack on frame', 'Wheel misalignment', 'Drivetrain noise',
                        'Missing parts', 'Defective part', 'Defective stitching', 'Defective item')
                                                                        as is_quality_defect,
    r.defect_origin_work_center                                         as defect_origin_work_center_code,
    r.disposition,
    r.refund_amount_usd,
    r.handling_cost_usd,
    r.refund_amount_usd + r.handling_cost_usd                           as total_cost_usd
from {{ ref('stg_cx_quality__customer_returns') }} as r
left join {{ ref('stg_aw_sales__sales_order_header') }} as h on h.sales_order_id = r.sales_order_id
where {{ month_start('r.return_date') }} <= date '{{ var("reporting_month") }}'
