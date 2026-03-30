-- =============================================================
-- stg_products
-- Camada Staging: limpeza e padronização da tabela raw.products
-- Fonte: raw.products
-- =============================================================

with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        -- Chaves
        product_id,
        upper(trim(sku))                    as sku,

        -- Atributos do produto
        trim(product_name)                  as product_name,
        initcap(trim(category))             as category,
        initcap(trim(subcategory))          as subcategory,
        initcap(trim(brand))                as brand,

        -- Preços (garantir positivo)
        case when unit_cost > 0 then unit_cost else 0 end   as unit_cost,
        case when unit_price > 0 then unit_price else 0 end as unit_price,

        -- Margem calculada na staging
        round(
            (unit_price - unit_cost) / nullif(unit_price, 0) * 100,
            2
        )                                   as margin_pct,

        -- Status
        is_active,
        created_at::date                    as product_created_date

    from source
    where product_id is not null
      and product_name is not null
)

select * from renamed
