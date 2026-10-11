-- Silver : aw_production__product_subcategory (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ProductSubcategoryID') }} as product_subcategory_id,
    {{ to_int('ProductCategoryID') }}    as product_category_id,
    {{ txt('Name') }}                    as name,
    {{ to_date('ModifiedDate') }}        as modified_date,
    _source
from {{ source('bronze', 'aw_production__product_subcategory') }}
