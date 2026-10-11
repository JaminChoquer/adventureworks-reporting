-- Un mois par ligne : axe temporel commun à tous les faits mensuels du reporting.
select
    month_start,
    min(year)                                                          as year,
    min(quarter)                                                       as quarter,
    min(month_number)                                                  as month_number,
    concat(
        case min(month_number)
            when 1 then 'Jan' when 2 then 'Feb' when 3 then 'Mar' when 4 then 'Apr'
            when 5 then 'May' when 6 then 'Jun' when 7 then 'Jul' when 8 then 'Aug'
            when 9 then 'Sep' when 10 then 'Oct' when 11 then 'Nov' else 'Dec'
        end,
        ' ', cast(min(year) as {{ dbt.type_string() }})
    )                                                                  as month_label,
    max(date_day)                                                      as month_end,
    sum(case when is_working_day then 1 else 0 end)                    as working_days,
    month_start <= date '{{ var("reporting_month") }}'                 as is_closed,
    month_start = date '{{ var("reporting_month") }}'                  as is_reporting_month
from {{ ref('dim_date') }}
group by month_start
