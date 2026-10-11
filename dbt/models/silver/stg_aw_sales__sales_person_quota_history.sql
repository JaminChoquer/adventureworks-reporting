-- Silver : aw_sales__sales_person_quota_history (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }} as business_entity_id,
    {{ to_date('QuotaDate') }}       as quota_date,
    {{ to_num('SalesQuota') }}       as sales_quota,
    {{ to_date('ModifiedDate') }}    as modified_date,
    _source
from {{ source('bronze', 'aw_sales__sales_person_quota_history') }}
