-- =============================================================
-- int_orders_enriched
-- Camada Intermediate: join entre orders, order_items e products
-- Grão: 1 linha por item de pedido (enriquecido)
-- =============================================================

with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

joined as (
    select
        -- Chaves originais
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        o.customer_id,

        -- Datas
        o.order_date,
        o.ship_date,
        o.days_to_ship,

        -- Atributos do pedido
        o.order_status,
        o.sales_channel,
        o.region,
        o.is_cancelled,

        -- Atributos do cliente
        c.customer_name,
        c.customer_segment,
        c.city                  as customer_city,
        c.state_code            as customer_state,

        -- Atributos do produto
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.unit_cost             as product_unit_cost,
        p.margin_pct            as product_margin_pct,

        -- Medidas financeiras
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,
        oi.item_total_amount,
        oi.item_gross_amount,
        oi.discount_amount,

        -- Custo total do item (para cálculo de margem)
        round(oi.quantity * p.unit_cost, 2)                 as item_total_cost,

        -- Margem do item em reais
        round(oi.item_total_amount - (oi.quantity * p.unit_cost), 2) as item_gross_margin

    from order_items oi
    inner join orders o      on oi.order_id  = o.order_id
    inner join products p    on oi.product_id = p.product_id
    inner join customers c   on o.customer_id = c.customer_id

    where not o.is_cancelled  -- excluir pedidos cancelados do fato principal
)

select * from joined
