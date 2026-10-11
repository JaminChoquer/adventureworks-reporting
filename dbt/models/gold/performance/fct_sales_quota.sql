-- Objectifs de vente trimestriels des commerciaux. Grain : commercial, trimestre.
select
    concat(cast(business_entity_id as {{ dbt.type_string() }}), '|',
           cast(quota_date as {{ dbt.type_string() }}))     as quota_key,
    business_entity_id                                      as sales_person_employee_id,
    quota_date,
    {{ month_start('quota_date') }}                         as month_start,
    sales_quota                                             as sales_quota_usd
from {{ ref('stg_aw_sales__sales_person_quota_history') }}
where {{ month_start('quota_date') }} between date '{{ var("calendar_start") }}' and date '{{ var("reporting_month") }}'
