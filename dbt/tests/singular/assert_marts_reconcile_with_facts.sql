-- Les agrégats mart conservent exactement les totaux des faits gold.
with checks as (
    select 'sales' as mart,
        (select sum(net_sales_usd) from {{ ref('mart_sales_monthly') }}) as mart_total,
        (select sum(net_sales_usd) from {{ ref('fct_sales_lines') }})    as fact_total
    union all
    select 'safety',
        (select sum(events) from {{ ref('mart_safety_monthly') }}),
        (select count(*) from {{ ref('fct_safety_events') }})
    union all
    select 'hr',
        (select sum(worked_hours) from {{ ref('mart_hr_monthly') }}),
        (select sum(worked_hours) from {{ ref('fct_hr_monthly') }})
    union all
    select 'production',
        (select sum(scrapped_qty) from {{ ref('mart_production_monthly') }}),
        (select sum(scrapped_qty) from {{ ref('fct_production_orders') }})
    union all
    select 'purchasing',
        (select sum(received_value_usd) from {{ ref('mart_purchasing_monthly') }}),
        (select sum(received_value_usd) from {{ ref('fct_purchase_lines') }})
    union all
    select 'quality',
        (select sum(nonconformities) from {{ ref('mart_quality_monthly') }}),
        (select count(*) from {{ ref('fct_nonconformities') }})
    union all
    select 'returns',
        (select sum(total_cost_usd) from {{ ref('mart_returns_monthly') }}),
        (select sum(total_cost_usd) from {{ ref('fct_customer_returns') }})
    union all
    select 'training',
        (select sum(required) from {{ ref('mart_training_monthly') }}),
        (select count(*) from {{ ref('fct_training_compliance') }})
)
select * from checks where abs(coalesce(mart_total, 0) - coalesce(fact_total, 0)) > 0.01
