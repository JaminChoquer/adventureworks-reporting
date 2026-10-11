-- Lignes d'achat, rattachées au mois de réception prévue. Grain : une ligne de commande fournisseur.
select
    d.purchase_order_detail_id,
    d.purchase_order_id,
    h.order_date,
    d.due_date,
    {{ month_start('d.due_date') }}                                      as month_start,
    h.vendor_id,
    h.employee_id                                                        as buyer_employee_id,
    h.ship_method_id,
    d.product_id,
    d.order_qty,
    d.received_qty,
    d.rejected_qty,
    d.stocked_qty,
    d.unit_price,
    d.line_total                                                         as ordered_value_usd,
    d.received_qty * d.unit_price                                        as received_value_usd,
    d.rejected_qty * d.unit_price                                        as rejected_value_usd,
    case when d.received_qty > 0 then d.rejected_qty / d.received_qty end as reject_rate,
    {{ dbt.datediff('h.order_date', 'd.due_date', 'day') }}              as lead_time_days
from {{ ref('stg_aw_purchasing__purchase_order_detail') }} as d
join {{ ref('stg_aw_purchasing__purchase_order_header') }} as h on h.purchase_order_id = d.purchase_order_id
where {{ month_start('d.due_date') }} between date '{{ var("calendar_start") }}' and date '{{ var("reporting_month") }}'
