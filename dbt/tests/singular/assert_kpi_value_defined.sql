-- Une valeur n'est vide que si le ratio est indéfini (dénominateur absent ou nul).
select kpi_code, month_start, numerator, denominator
from {{ ref('kpi_monthly') }}
where value is null
  and coalesce(denominator, 0) > 0
