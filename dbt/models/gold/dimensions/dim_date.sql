-- Calendrier quotidien de la période de reporting, avec jours ouvrés de l'entreprise.
with days as (
    {{ date_series(var('calendar_start'), var('calendar_end')) }}
)

select
    d.date_day,
    {{ month_start('d.date_day') }}                                   as month_start,
    extract(year from d.date_day)                                     as year,
    extract(quarter from d.date_day)                                  as quarter,
    extract(month from d.date_day)                                    as month_number,
    {{ iso_day_of_week('d.date_day') }}                               as iso_day_of_week,
    {{ iso_day_of_week('d.date_day') }} <= 5                          as is_weekday,
    h.holiday_date is not null                                        as is_company_holiday,
    h.holiday_name,
    ({{ iso_day_of_week('d.date_day') }} <= 5 and h.holiday_date is null) as is_working_day
from days as d
left join {{ ref('company_holidays') }} as h on h.holiday_date = d.date_day
