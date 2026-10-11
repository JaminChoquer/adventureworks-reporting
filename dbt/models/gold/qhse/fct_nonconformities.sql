-- Non-conformités, toutes sources confondues. Grain : une non-conformité.
select
    nc_id,
    detected_on,
    {{ month_start('detected_on') }}                              as month_start,
    source                                                        as nc_source,
    severity,
    description,
    work_center                                                   as work_center_code,
    coalesce(location_id, 0)                                      as location_key,
    product_id,
    vendor_id,
    work_order_id,
    purchase_order_id,
    purchase_order_detail_id,
    sales_order_id,
    audit_id,
    rma_id,
    scrap_reason_id,
    coalesce(qty_affected, 0)                                     as qty_affected,
    coalesce(estimated_cost_usd, 0)                               as estimated_cost_usd,
    root_cause_category,
    status,
    closed_on,
    {{ dbt.datediff('detected_on', 'closed_on', 'day') }}         as days_to_close,
    closed_on is null or closed_on > (
        select max(month_end) from {{ ref('dim_month') }} where is_reporting_month
    )                                                             as is_open_at_reporting_end
from {{ ref('stg_cx_quality__nonconformities') }}
where {{ month_start('detected_on') }} <= date '{{ var("reporting_month") }}'
