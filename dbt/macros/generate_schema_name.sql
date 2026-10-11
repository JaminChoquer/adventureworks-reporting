{#
  Les modèles sont écrits dans le jeu de données indiqué par leur configuration
  (silver ou gold), sans préfixe : bronze, silver et gold restent lisibles côte à côte.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}{{ target.schema }}{%- else -%}{{ custom_schema_name | trim }}{%- endif -%}
{%- endmacro %}
