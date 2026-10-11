-- Silver : aw_sales__special_offer (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('SpecialOfferID') }} as special_offer_id,
    {{ txt('Description') }}       as description,
    {{ to_num('DiscountPct') }}    as discount_pct,
    {{ txt('Type') }}              as type,
    {{ txt('Category') }}          as category,
    {{ to_date('StartDate') }}     as start_date,
    {{ to_date('EndDate') }}       as end_date,
    {{ to_int('MinQty') }}         as min_qty,
    {{ to_int('MaxQty') }}         as max_qty,
    {{ to_date('ModifiedDate') }}  as modified_date,
    _source
from {{ source('bronze', 'aw_sales__special_offer') }}
