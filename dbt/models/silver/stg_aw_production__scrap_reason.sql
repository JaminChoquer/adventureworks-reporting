-- Silver : aw_production__scrap_reason (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ScrapReasonID') }} as scrap_reason_id,
    {{ txt('Name') }}             as name,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__scrap_reason') }}
