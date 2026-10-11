-- Silver : aw_sales__sales_territory (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('TerritoryID') }}    as territory_id,
    {{ txt('Name') }}              as name,
    {{ txt('CountryRegionCode') }} as country_region_code,
    {{ txt('Group') }}             as territory_group,
    {{ to_num('SalesYTD') }}       as sales_ytd,
    {{ to_num('SalesLastYear') }}  as sales_last_year,
    {{ to_num('CostYTD') }}        as cost_ytd,
    {{ to_num('CostLastYear') }}   as cost_last_year,
    {{ to_date('ModifiedDate') }}  as modified_date,
    _source
from {{ source('bronze', 'aw_sales__sales_territory') }}
