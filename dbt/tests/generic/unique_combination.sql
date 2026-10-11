{#- Vérifie qu'une combinaison de colonnes identifie chaque ligne de façon unique. -#}
{% test unique_combination(model, columns) %}
select {{ columns | join(', ') }}, count(*) as n_rows
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
