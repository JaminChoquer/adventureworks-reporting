-- Non-conformités agrégées par mois, source, gravité, atelier et cause racine.
select
    month_start,
    nc_source,
    severity,
    coalesce(work_center_code, 'Unassigned')            as work_center_code,
    location_key,
    coalesce(root_cause_category, 'Not analysed')       as root_cause_category,
    count(*)                                            as nonconformities,
    sum(case when is_open_at_reporting_end then 1 else 0 end) as open_at_reporting_end,
    sum(qty_affected)                                   as qty_affected,
    sum(estimated_cost_usd)                             as estimated_cost_usd,
    sum(days_to_close)                                  as days_to_close_total,
    sum(case when days_to_close is not null then 1 else 0 end) as closed_count
from {{ ref('fct_nonconformities') }}
group by 1, 2, 3, 4, 5, 6
