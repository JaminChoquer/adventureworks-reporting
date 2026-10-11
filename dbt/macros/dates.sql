{# Fonctions de dates écrites pour BigQuery et DuckDB (tests locaux). #}

{% macro date_series(start_date, end_date) %}{{ return(adapter.dispatch('date_series')(start_date, end_date)) }}{% endmacro %}

{% macro bigquery__date_series(start_date, end_date) -%}
select d as date_day from unnest(generate_date_array(date '{{ start_date }}', date '{{ end_date }}')) as d
{%- endmacro %}

{% macro default__date_series(start_date, end_date) -%}
select cast(d as date) as date_day from generate_series(date '{{ start_date }}', date '{{ end_date }}', interval 1 day) as t(d)
{%- endmacro %}

{# Jour de la semaine ISO : 1 = lundi, 7 = dimanche #}
{% macro iso_day_of_week(col) %}{{ return(adapter.dispatch('iso_day_of_week')(col)) }}{% endmacro %}
{% macro bigquery__iso_day_of_week(col) %}mod(extract(dayofweek from {{ col }}) + 5, 7) + 1{% endmacro %}
{% macro default__iso_day_of_week(col) %}isodow({{ col }}){% endmacro %}

{# Premier jour du mois #}
{% macro month_start(col) %}cast({{ dbt.date_trunc('month', col) }} as date){% endmacro %}
