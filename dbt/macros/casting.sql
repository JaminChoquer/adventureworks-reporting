{#
  Conversions de la couche silver. Les tables bronze sont entièrement en texte :
  ces macros typent chaque colonne de façon tolérante (valeur invalide = NULL) et
  identique sur BigQuery et DuckDB, ce qui permet de tester le projet en local.
#}

{% macro type_local_datetime() %}{{ return(adapter.dispatch('type_local_datetime')()) }}{% endmacro %}
{% macro default__type_local_datetime() %}timestamp{% endmacro %}
{% macro bigquery__type_local_datetime() %}datetime{% endmacro %}

{% macro txt(col) -%}
nullif(trim({{ adapter.quote(col) }}), '')
{%- endmacro %}

{% macro to_int(col) -%}
{{ dbt.safe_cast(adapter.quote(col), dbt.type_int()) }}
{%- endmacro %}

{% macro to_num(col) -%}
{#- AdventureWorks exporte les décimaux sans zéro initial (« .2100 ») -#}
{%- set c = adapter.quote(col) -%}
{{ dbt.safe_cast("case when " ~ c ~ " like '-.%' then concat('-0', substr(" ~ c ~ ", 2)) when " ~ c ~ " like '.%' then concat('0', " ~ c ~ ") else " ~ c ~ " end", dbt.type_numeric()) }}
{%- endmacro %}

{% macro to_bool(col) -%}
({{ dbt.safe_cast(adapter.quote(col), dbt.type_int()) }} = 1)
{%- endmacro %}

{% macro to_date(col) -%}
{{ dbt.safe_cast("substr(" ~ adapter.quote(col) ~ ", 1, 10)", 'date') }}
{%- endmacro %}

{% macro to_datetime(col) -%}
{{ dbt.safe_cast("replace(substr(" ~ adapter.quote(col) ~ ", 1, 19), 'T', ' ')", type_local_datetime()) }}
{%- endmacro %}

{% macro to_month(col) -%}
{#- Mois au format AAAA-MM, converti en premier jour du mois -#}
{{ dbt.safe_cast("concat(" ~ adapter.quote(col) ~ ", '-01')", 'date') }}
{%- endmacro %}

{# Nombre à virgule flottante double précision (FLOAT64 sur BigQuery, DOUBLE ailleurs) #}
{% macro type_double() %}{{ return(adapter.dispatch('type_double')()) }}{% endmacro %}
{% macro default__type_double() %}double{% endmacro %}
{% macro bigquery__type_double() %}float64{% endmacro %}
