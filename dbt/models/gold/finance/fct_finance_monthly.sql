-- Indicateurs financiers de gestion, au format long. Grain : mois, poste.
-- Les postes sont juxtaposés, sans résultat global : le coût standard des ventes inclut
-- déjà la main-d'œuvre, un compte de résultat complet la compterait deux fois.
with lines as (
    select month_start, 'NET_SALES' as account_code, sum(net_sales_usd) as amount_usd, 'fct_sales_lines' as source_model
    from {{ ref('fct_sales_lines') }} group by 1
    union all
    select month_start, 'FREIGHT_BILLED', sum(freight_billed_usd), 'fct_sales_lines'
    from {{ ref('fct_sales_lines') }} group by 1
    union all
    select month_start, 'COST_OF_SALES_STD', sum(cost_of_sales_usd), 'fct_sales_lines'
    from {{ ref('fct_sales_lines') }} group by 1
    union all
    select month_start, 'GROSS_MARGIN_STD', sum(gross_margin_usd), 'fct_sales_lines'
    from {{ ref('fct_sales_lines') }} group by 1
    union all
    select month_start, 'PAYROLL', sum(payroll_cost_usd), 'fct_payroll_monthly'
    from {{ ref('fct_payroll_monthly') }} group by 1
    union all
    select month_start, 'TEMP_LABOR', sum(temp_labor_cost_usd), 'fct_hours_worked'
    from {{ ref('fct_hours_worked') }} group by 1
    union all
    select month_start, 'SCRAP_COST', sum(scrap_cost_usd), 'fct_production_orders'
    from {{ ref('fct_production_orders') }} group by 1
    union all
    select month_start, 'CUSTOMER_RETURNS_COST', sum(total_cost_usd), 'fct_customer_returns'
    from {{ ref('fct_customer_returns') }} group by 1
    union all
    select month_start, 'PURCHASING_SPEND', sum(received_value_usd), 'fct_purchase_lines'
    from {{ ref('fct_purchase_lines') }} group by 1
)

select
    concat(cast(l.month_start as {{ dbt.type_string() }}), '|', l.account_code) as finance_key,
    l.month_start,
    l.account_code,
    a.account_name,
    a.account_group,
    a.is_cost,
    a.is_subtotal,
    a.sort_order,
    l.amount_usd,
    l.source_model
from lines as l
join {{ ref('finance_accounts') }} as a on a.account_code = l.account_code
