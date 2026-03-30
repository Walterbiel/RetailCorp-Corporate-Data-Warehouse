-- =============================================================
-- dim_products
-- Dimensão de produtos para o Star Schema
-- Grão: 1 linha por produto (SCD Tipo 1)
-- =============================================================

with stg_products as (
    select * from {{ ref('stg_products') }}
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['product_id']) }}  as product_sk,

        -- Natural key
        product_id,
        sku,

        -- Atributos do produto
        product_name,
        category,
        subcategory,
        brand,

        -- Preços e margem
        unit_cost,
        unit_price,
        margin_pct,

        -- Classificação de margem para analytics
        case
            when margin_pct >= 50 then 'Alta Margem'
            when margin_pct >= 25 then 'Margem Média'
            when margin_pct >= 0  then 'Margem Baixa'
            else 'Prejuízo'
        end                     as margin_tier,

        -- Status e metadados
        is_active,
        product_created_date,
        current_timestamp       as dw_loaded_at

    from stg_products
)

select * from final
