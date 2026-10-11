-- Ordres de fabrication terminés, rattachés au mois de fin. Grain : un ordre de fabrication.
with routing as (
    select
        work_order_id,
        count(*)                                                        as operations,
        sum(actual_resource_hrs)                                        as actual_resource_hours,
        sum(planned_cost)                                               as planned_cost_usd,
        sum(actual_cost)                                                as actual_cost_usd,
        sum(case when actual_end_date > scheduled_end_date then 1 else 0 end) as late_operations
    from {{ ref('stg_aw_production__work_order_routing') }}
    group by work_order_id
),

orders as (
    select
        w.*,
        coalesce(c.standard_cost, p.standard_cost) as unit_standard_cost
    from {{ ref('stg_aw_production__work_order') }} as w
    left join {{ ref('stg_aw_production__product_cost_history') }} as c
        on  c.product_id = w.product_id
        and w.start_date >= c.start_date
        and (c.end_date is null or w.start_date < c.end_date)
    left join {{ ref('stg_aw_production__product') }} as p on p.product_id = w.product_id
)

select
    o.work_order_id,
    o.product_id,
    o.start_date,
    o.end_date,
    o.due_date,
    {{ month_start('o.end_date') }}                                       as month_start,
    o.order_qty,
    o.stocked_qty,
    o.scrapped_qty,
    case when o.order_qty > 0 then o.scrapped_qty / o.order_qty end       as scrap_rate,
    o.scrap_reason_id,
    s.name                                                                as scrap_reason,
    {{ dbt.datediff('o.start_date', 'o.end_date', 'day') }}               as lead_time_days,
    o.end_date > o.due_date                                               as is_late,
    greatest({{ dbt.datediff('o.due_date', 'o.end_date', 'day') }}, 0)    as days_late,
    o.unit_standard_cost,
    o.scrapped_qty * o.unit_standard_cost                                 as scrap_cost_usd,
    coalesce(r.operations, 0)                                             as operations,
    coalesce(r.late_operations, 0)                                        as late_operations,
    coalesce(r.actual_resource_hours, 0)                                  as actual_resource_hours,
    r.planned_cost_usd,
    r.actual_cost_usd
from orders as o
left join routing as r on r.work_order_id = o.work_order_id
left join {{ ref('stg_aw_production__scrap_reason') }} as s on s.scrap_reason_id = o.scrap_reason_id
where {{ month_start('o.end_date') }} between date '{{ var("calendar_start") }}' and date '{{ var("reporting_month") }}'
