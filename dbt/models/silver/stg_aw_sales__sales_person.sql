-- Silver : aw_sales__sales_person (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }} as business_entity_id,
    {{ to_int('TerritoryID') }}      as territory_id,
    {{ to_num('SalesQuota') }}       as sales_quota,
    {{ to_num('Bonus') }}            as bonus,
    {{ to_num('CommissionPct') }}    as commission_pct,
    {{ to_num('SalesYTD') }}         as sales_ytd,
    {{ to_num('SalesLastYear') }}    as sales_last_year,
    {{ to_date('ModifiedDate') }}    as modified_date,
    _source
from {{ source('bronze', 'aw_sales__sales_person') }}
