-- Chaque mois, la marge brute standard égale le chiffre d'affaires moins le coût des ventes.
with p as (
    select
        month_start,
        sum(case when account_code = 'NET_SALES' then amount_usd else 0 end)         as sales,
        sum(case when account_code = 'COST_OF_SALES_STD' then amount_usd else 0 end) as cost,
        sum(case when account_code = 'GROSS_MARGIN_STD' then amount_usd else 0 end) as margin
    from {{ ref('fct_finance_monthly') }}
    group by month_start
)
select * from p where abs(sales - cost - margin) > 0.01
