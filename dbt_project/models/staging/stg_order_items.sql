-- =============================================================
-- stg_order_items
-- Camada Staging: limpeza e cálculos da tabela raw.order_items
-- Fonte: raw.order_items
-- =============================================================

with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed as (
    select
        -- Chaves
        order_item_id,
        order_id,
        product_id,

        -- Quantidades e preços
        quantity,
        unit_price,
        round(discount_pct, 2)                              as discount_pct,

        -- Valor total do item com desconto aplicado
        round(
            quantity * unit_price * (1 - discount_pct / 100.0),
            2
        )                                                   as item_total_amount,

        -- Valor total sem desconto
        round(quantity * unit_price, 2)                     as item_gross_amount,

        -- Valor do desconto em reais
        round(
            quantity * unit_price * (discount_pct / 100.0),
            2
        )                                                   as discount_amount,

        created_at

    from source
    where order_item_id is not null
      and order_id is not null
      and product_id is not null
      and quantity > 0
)

select * from renamed
