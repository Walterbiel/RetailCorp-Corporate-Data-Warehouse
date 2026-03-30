-- =============================================================
-- Macro: generate_surrogate_key
-- Gera uma surrogate key (hash MD5) a partir de uma lista de colunas
-- Uso: {{ generate_surrogate_key(['col1', 'col2']) }}
-- =============================================================
{% macro generate_surrogate_key(field_list) %}
    {{ dbt_utils.generate_surrogate_key(field_list) }}
{% endmacro %}


-- =============================================================
-- Macro: cents_to_dollars
-- Converte valor em centavos para reais
-- =============================================================
{% macro cents_to_dollars(column_name, scale=2) %}
    round({{ column_name }} / 100.0, {{ scale }})
{% endmacro %}
