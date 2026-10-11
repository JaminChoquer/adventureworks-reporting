-- Produits avec leur hiérarchie. Les pièces sans sous-catégorie sont des composants internes.
select
    p.product_id,
    p.name                                       as product_name,
    p.product_number,
    p.color,
    coalesce(c.name, 'Component part')           as category_name,
    coalesce(s.name, 'Component part')           as subcategory_name,
    p.make_flag                                  as is_manufactured,
    p.finished_goods_flag                        as is_finished_good,
    p.standard_cost,
    p.list_price,
    p.days_to_manufacture
from {{ ref('stg_aw_production__product') }} as p
left join {{ ref('stg_aw_production__product_subcategory') }} as s on s.product_subcategory_id = p.product_subcategory_id
left join {{ ref('stg_aw_production__product_category') }} as c on c.product_category_id = s.product_category_id
