-- =============================================================
-- fact_sales
-- Tabela Fato central do Star Schema
-- Grão: 1 linha por item de pedido entregue
-- Chaves estrangeiras: customer_sk, product_sk, date_sk
-- =============================================================

with int_orders as (
    select * from {{ ref('int_orders_enriched') }}
),

dim_customers as (
    select customer_sk, customer_id from {{ ref('dim_customers') }}
),

dim_products as (
    select product_sk, product_id from {{ ref('dim_products') }}
),

dim_date as (
    select date_sk, full_date from {{ ref('dim_date') }}
),

final as (
    select
        -- Surrogate key da linha do fato
        {{ dbt_utils.generate_surrogate_key(['o.order_item_id']) }}  as sales_sk,

        -- Natural key (para rastreabilidade)
        o.order_item_id,
        o.order_id,

        -- Chaves estrangeiras para as dimensões (surrogate keys)
        c.customer_sk,
        p.product_sk,
        d.date_sk,

        -- Atributos degenerados (não merecem dimensão própria)
        o.sales_channel,
        o.region,
        o.order_status,

        -- Medidas aditivas
        o.quantity,
        o.unit_price,
        o.discount_pct,
        o.discount_amount,
        o.item_gross_amount,
        o.item_total_amount,   -- receita líquida
        o.item_total_cost,
        o.item_gross_margin,

        -- Metadados
        o.days_to_ship,
        current_timestamp as dw_loaded_at

    from int_orders o
    inner join dim_customers c  on o.customer_id = c.customer_id
    inner join dim_products p   on o.product_id  = p.product_id
    inner join dim_date d       on o.order_date  = d.full_date
)

select * from final
