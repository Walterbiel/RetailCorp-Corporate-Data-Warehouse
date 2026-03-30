-- =============================================================
-- rpt_sales_summary
-- Relatório agregado de vendas: KPIs diários por produto
-- Grão: 1 linha por dia + categoria + canal de venda
-- Usado diretamente pelo dashboard Streamlit
-- =============================================================

with fact_sales as (
    select * from {{ ref('fact_sales') }}
),

dim_products as (
    select * from {{ ref('dim_products') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

aggregated as (
    select
        -- Dimensões de agrupamento
        dd.full_date,
        dd.year_month,
        dd.year_quarter,
        dd.year_number,
        dd.month_number,
        dd.month_name_short,
        dd.day_name_short,
        dd.is_weekend,

        dp.category,
        dp.subcategory,
        dp.brand,
        dp.margin_tier,

        fs.sales_channel,
        fs.region,

        -- KPIs de volume
        count(distinct fs.order_id)         as num_orders,
        count(fs.sales_sk)                  as num_items_sold,
        sum(fs.quantity)                    as total_quantity,

        -- KPIs financeiros
        round(sum(fs.item_gross_amount), 2) as gross_revenue,
        round(sum(fs.discount_amount), 2)   as total_discounts,
        round(sum(fs.item_total_amount), 2) as net_revenue,
        round(sum(fs.item_total_cost), 2)   as total_cost,
        round(sum(fs.item_gross_margin), 2) as gross_margin,

        -- KPIs derivados
        round(
            sum(fs.item_total_amount) / nullif(count(distinct fs.order_id), 0),
            2
        )                                   as avg_order_value,

        round(
            sum(fs.item_gross_margin) / nullif(sum(fs.item_total_amount), 0) * 100,
            2
        )                                   as margin_pct

    from fact_sales fs
    inner join dim_products dp on fs.product_sk = dp.product_sk
    inner join dim_date dd     on fs.date_sk    = dd.date_sk

    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
)

select * from aggregated
