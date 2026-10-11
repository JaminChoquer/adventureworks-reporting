-- Chaque indicateur a une ligne pour chaque mois clôturé.
with expected as (
    select count(*) as n
    from {{ ref('dim_month') }} as m
    cross join {{ ref('kpi_definitions') }} as d
    where m.is_closed
),
actual as (select count(*) as n from {{ ref('kpi_monthly') }})
select e.n as expected_rows, a.n as actual_rows
from expected as e cross join actual as a
where e.n != a.n
