-- Relevés environnementaux mensuels, au format long. Grain : mois, zone, indicateur.
-- La zone 0 regroupe le bâtiment et les services généraux.
select
    concat(cast(month as {{ dbt.type_string() }}), '|',
           cast(coalesce(location_id, 0) as {{ dbt.type_string() }}), '|', indicator) as reading_key,
    month                                              as month_start,
    coalesce(location_id, 0)                           as location_key,
    indicator,
    case
        when indicator in ('electricity_kwh', 'natural_gas_kwh') then 'Energy'
        when indicator = 'water_m3' then 'Water'
        when indicator = 'voc_kg' then 'Air emissions'
        else 'Waste'
    end                                                as theme,
    indicator like '%recycled%'                        as is_recycled_share,
    value,
    unit,
    source                                             as measurement_source
from {{ ref('stg_cx_environment__monthly_readings') }}
where month <= date '{{ var("reporting_month") }}'
