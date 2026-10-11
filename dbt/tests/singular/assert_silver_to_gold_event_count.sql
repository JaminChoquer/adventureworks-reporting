-- Tous les événements de silver jusqu'au mois de reporting se retrouvent dans gold.
with s as (
    select count(*) as n
    from {{ ref('stg_cx_ehs__incidents') }}
    where {{ month_start('cast(occurred_at as date)') }} <= date '{{ var("reporting_month") }}'
),
g as (select count(*) as n from {{ ref('fct_safety_events') }})
select s.n as silver_rows, g.n as gold_rows
from s cross join g
where s.n != g.n
