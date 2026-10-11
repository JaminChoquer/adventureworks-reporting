-- Silver : cx_quality__customer_returns (données complémentaires), typée et renommée, sans règle métier.
select
    {{ txt('rma_id') }}                    as rma_id,
    {{ to_date('return_date') }}           as return_date,
    {{ to_int('sales_order_id') }}         as sales_order_id,
    {{ to_int('sales_order_detail_id') }}  as sales_order_detail_id,
    {{ to_int('product_id') }}             as product_id,
    {{ to_int('qty_returned') }}           as qty_returned,
    {{ txt('return_reason') }}             as return_reason,
    {{ txt('defect_origin_work_center') }} as defect_origin_work_center,
    {{ txt('disposition') }}               as disposition,
    {{ to_num('refund_amount_usd') }}      as refund_amount_usd,
    {{ to_num('handling_cost_usd') }}      as handling_cost_usd,
    _source
from {{ source('bronze', 'cx_quality__customer_returns') }}
