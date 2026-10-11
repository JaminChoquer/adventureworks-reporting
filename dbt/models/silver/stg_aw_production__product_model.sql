-- Silver : aw_production__product_model (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ProductModelID') }}    as product_model_id,
    {{ txt('Name') }}                 as name,
    {{ to_datetime('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__product_model') }}
