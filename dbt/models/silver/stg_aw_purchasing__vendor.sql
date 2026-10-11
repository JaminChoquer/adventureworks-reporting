-- Silver : aw_purchasing__vendor (AdventureWorks), typée et renommée, sans règle métier.
select
    {{ to_int('BusinessEntityID') }}       as business_entity_id,
    {{ txt('AccountNumber') }}             as account_number,
    {{ txt('Name') }}                      as name,
    {{ to_int('CreditRating') }}           as credit_rating,
    {{ to_bool('PreferredVendorStatus') }} as preferred_vendor_status,
    {{ to_bool('ActiveFlag') }}            as active_flag,
    {{ txt('PurchasingWebServiceURL') }}   as purchasing_web_service_url,
    {{ to_date('ModifiedDate') }}          as modified_date,
    _source
from {{ source('bronze', 'aw_purchasing__vendor') }}
