-- =============================================================
-- dim_customers
-- Dimensão de clientes para o Star Schema
-- Grão: 1 linha por cliente único (SCD Tipo 1 — sobrescreve)
-- =============================================================

with stg_customers as (
    select * from {{ ref('stg_customers') }}
),

final as (
    select
        -- Surrogate key (hash) — boa prática em DW
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }}  as customer_sk,

        -- Natural key (do sistema de origem)
        customer_id,

        -- Atributos descritivos
        customer_name,
        email,
        phone_digits,
        city,
        state_code,
        country_code,
        customer_segment,
        customer_since_date,

        -- Metadados de auditoria
        updated_at,
        current_timestamp as dw_loaded_at

    from stg_customers
)

select * from final
