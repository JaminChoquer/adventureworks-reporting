-- Silver : aw_production__product_cost_history (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('ProductID') }}     as product_id,
    {{ to_date('StartDate') }}    as start_date,
    {{ to_date('EndDate') }}      as end_date,
    {{ to_num('StandardCost') }}  as standard_cost,
    {{ to_date('ModifiedDate') }} as modified_date,
    _source
from {{ source('bronze', 'aw_production__product_cost_history') }}
