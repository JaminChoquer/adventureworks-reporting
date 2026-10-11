-- Le chiffre d'affaires gold égale la somme des lignes silver expédiées sur la période.
with s as (
    select sum(d.line_total) as amount
    from {{ ref('stg_aw_sales__sales_order_detail') }} as d
    join {{ ref('stg_aw_sales__sales_order_header') }} as h on h.sales_order_id = d.sales_order_id
    where {{ month_start('h.ship_date') }} between date '{{ var("calendar_start") }}' and date '{{ var("reporting_month") }}'
),
g as (select sum(net_sales_usd) as amount from {{ ref('fct_sales_lines') }})
select s.amount as silver_amount, g.amount as gold_amount
from s cross join g
where abs(s.amount - g.amount) > 0.01
