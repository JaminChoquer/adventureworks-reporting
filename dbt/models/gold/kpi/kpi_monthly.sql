-- Indicateurs mensuels du reporting, toutes thématiques. Grain : mois, indicateur.
-- Chaque indicateur est stocké avec son numérateur et son dénominateur : la valeur sur
-- 12 mois glissants est recalculée à partir des sommes (somme des numérateurs / somme des
-- dénominateurs), jamais en moyennant des taux mensuels.
-- Sans dénominateur, la valeur est le numérateur (comptage ou montant) et la valeur sur
-- 12 mois est leur cumul. Pour l'effectif, le dénominateur vaut 1 : la valeur sur 12 mois
-- est l'effectif moyen.

with hours as (
    select month_start, sum(worked_hours) as hours_worked,
           sum(case when worker_type = 'Temporary' then worked_hours else 0 end) as temp_hours
    from {{ ref('fct_hours_worked') }} group by 1
),
safety as (
    select month_start,
           sum(case when is_lost_time_injury then 1 else 0 end) as lti,
           sum(case when is_recordable then 1 else 0 end)       as recordables,
           sum(case when is_proactive_report then 1 else 0 end) as proactive,
           sum(days_lost)                                       as days_lost
    from {{ ref('fct_safety_events') }} group by 1
),
compliance as (
    select month_start, sum(case when is_compliant then 1 else 0 end) as compliant, count(*) as required
    from {{ ref('fct_training_compliance') }} group by 1
),
audits as (
    select month_start, sum(score) as score_sum, count(*) as audits
    from {{ ref('fct_audits') }} where audit_type = '5S' group by 1
),
ncs as (
    select month_start, count(*) as nc_count from {{ ref('fct_nonconformities') }} group by 1
),
returns as (
    select month_start, sum(qty_returned) as units_returned, sum(total_cost_usd) as returns_cost
    from {{ ref('fct_customer_returns') }} group by 1
),
env as (
    select month_start,
           sum(case when indicator in ('electricity_kwh', 'natural_gas_kwh') then value else 0 end) as energy_kwh,
           sum(case when indicator = 'voc_kg' then value else 0 end) as voc_kg,
           sum(case when indicator like 'waste%' and not is_recycled_share then value else 0 end) as waste_kg,
           sum(case when indicator like 'waste%' and is_recycled_share then value else 0 end) as recycled_kg
    from {{ ref('fct_environment_readings') }} group by 1
),
sales as (
    select month_start, sum(net_sales_usd) as net_sales, sum(order_qty) as units,
           count(distinct sales_order_id) as orders
    from {{ ref('fct_sales_lines') }} group by 1
),
production as (
    select month_start, count(*) as work_orders,
           sum(case when is_late then 0 else 1 end) as on_time,
           sum(scrapped_qty) as scrapped, sum(order_qty) as ordered, sum(scrap_cost_usd) as scrap_cost
    from {{ ref('fct_production_orders') }} group by 1
),
purchasing as (
    select month_start, sum(rejected_qty) as rejected, sum(received_qty) as received
    from {{ ref('fct_purchase_lines') }} group by 1
),
finance as (
    select month_start,
           sum(case when account_code = 'GROSS_MARGIN_STD' then amount_usd else 0 end) as gross_margin,
           sum(case when account_code = 'PAYROLL' then amount_usd else 0 end)          as payroll,
           sum(case when account_code = 'TEMP_LABOR' then amount_usd else 0 end)       as temp_labor,
           sum(case when account_code = 'PURCHASING_SPEND' then amount_usd else 0 end) as purchasing
    from {{ ref('fct_finance_monthly') }} group by 1
),
hr as (
    select month_start, count(*) as headcount, sum(scheduled_hours) as scheduled,
           sum(absence_hours) as absence, sum(overtime_hours) as overtime, sum(training_hours) as training
    from {{ ref('fct_hr_monthly') }} group by 1
),

months as (
    select month_start from {{ ref('dim_month') }} where is_closed
),

measures as (
    {%- set rows = [
        ('LTIFR', 's.lti', 'h.hours_worked'),
        ('SEVERITY_RATE', 's.days_lost', 'h.hours_worked'),
        ('TRIR', 's.recordables', 'h.hours_worked'),
        ('LOST_TIME_INJURIES', 's.lti', 'null'),
        ('PROACTIVE_REPORTS', 's.proactive', 'null'),
        ('TRAINING_COMPLIANCE', 'c.compliant', 'c.required'),
        ('AUDIT_5S_SCORE', 'a.score_sum', 'a.audits'),
        ('NONCONFORMITIES', 'n.nc_count', 'null'),
        ('CUSTOMER_RETURN_RATE', 'r.units_returned', 'sl.units'),
        ('COST_OF_NON_QUALITY', 'coalesce(p.scrap_cost, 0) + coalesce(r.returns_cost, 0)', 'null'),
        ('ENERGY_CONSUMPTION', 'e.energy_kwh', 'null'),
        ('VOC_EMISSIONS', 'e.voc_kg', 'null'),
        ('WASTE_RECYCLING_RATE', 'e.recycled_kg', 'e.waste_kg'),
        ('NET_SALES', 'sl.net_sales', 'null'),
        ('UNITS_SHIPPED', 'sl.units', 'null'),
        ('ORDERS_SHIPPED', 'sl.orders', 'null'),
        ('AVERAGE_ORDER_VALUE', 'sl.net_sales', 'sl.orders'),
        ('PRODUCTION_ON_TIME', 'p.on_time', 'p.work_orders'),
        ('SCRAP_RATE', 'p.scrapped', 'p.ordered'),
        ('SUPPLIER_REJECT_RATE', 'pu.rejected', 'pu.received'),
        ('GROSS_MARGIN', 'f.gross_margin', 'null'),
        ('GROSS_MARGIN_RATE', 'f.gross_margin', 'sl.net_sales'),
        ('PAYROLL', 'f.payroll', 'null'),
        ('TEMP_LABOR_COST', 'f.temp_labor', 'null'),
        ('NON_QUALITY_SHARE', 'coalesce(p.scrap_cost, 0) + coalesce(r.returns_cost, 0)', 'sl.net_sales'),
        ('PURCHASING_SPEND', 'f.purchasing', 'null'),
        ('HEADCOUNT', 'hr.headcount', '1'),
        ('ABSENTEEISM_RATE', 'hr.absence', 'hr.scheduled'),
        ('OVERTIME_RATE', 'hr.overtime', 'hr.scheduled'),
        ('TEMP_LABOR_SHARE', 'h.temp_hours', 'h.hours_worked'),
        ('TRAINING_HOURS_PER_EMPLOYEE', 'hr.training', 'hr.headcount'),
    ] %}
    {%- for code, num, den in rows %}
    select
        m.month_start,
        '{{ code }}' as kpi_code,
        cast({{ num }} as {{ type_double() }}) as numerator,
        cast({{ den }} as {{ type_double() }}) as denominator
    from months as m
    left join hours as h       on h.month_start = m.month_start
    left join safety as s      on s.month_start = m.month_start
    left join compliance as c  on c.month_start = m.month_start
    left join audits as a      on a.month_start = m.month_start
    left join ncs as n         on n.month_start = m.month_start
    left join returns as r     on r.month_start = m.month_start
    left join env as e         on e.month_start = m.month_start
    left join sales as sl      on sl.month_start = m.month_start
    left join production as p  on p.month_start = m.month_start
    left join purchasing as pu on pu.month_start = m.month_start
    left join finance as f     on f.month_start = m.month_start
    left join hr               on hr.month_start = m.month_start
    {%- if not loop.last %}
    union all
    {%- endif %}
    {%- endfor %}
),

-- Un mois sans événement compte zéro, pas « inconnu »
completed as (
    select
        month_start,
        kpi_code,
        coalesce(numerator, 0) as numerator,
        denominator,
        kpi_code in ({% for code, num, den in rows if den == 'null' %}'{{ code }}'{% if not loop.last %}, {% endif %}{% endfor %}) as is_additive
    from measures
),

valued as (
    select
        c.*,
        d.factor,
        case
            when c.is_additive then c.numerator
            when c.denominator > 0 then d.factor * c.numerator / c.denominator
        end as value,
        sum(c.numerator) over w12   as numerator_12m,
        sum(c.denominator) over w12 as denominator_12m,
        count(*) over w12           as months_in_window
    from completed as c
    join {{ ref('kpi_definitions') }} as d on d.kpi_code = c.kpi_code
    window w12 as (partition by c.kpi_code order by c.month_start rows between 11 preceding and current row)
)

select
    concat(cast(v.month_start as {{ dbt.type_string() }}), '|', v.kpi_code) as kpi_key,
    v.month_start,
    d.theme,
    v.kpi_code,
    d.kpi_name,
    d.unit,
    d.higher_is_better,
    d.sort_order,
    v.numerator,
    v.denominator,
    v.value,
    lag(v.value) over (partition by v.kpi_code order by v.month_start)    as previous_month_value,
    lag(v.value, 12) over (partition by v.kpi_code order by v.month_start) as same_month_last_year_value,
    case
        when v.is_additive then v.numerator_12m
        when v.denominator_12m > 0 then v.factor * v.numerator_12m / v.denominator_12m
    end                                                                    as rolling_12m_value,
    v.months_in_window = 12                                                as is_rolling_12m_complete,
    d.definition,
    d.source_model
from valued as v
join {{ ref('kpi_definitions') }} as d on d.kpi_code = v.kpi_code
