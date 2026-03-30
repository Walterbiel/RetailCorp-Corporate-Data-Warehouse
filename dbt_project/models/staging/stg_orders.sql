-- =============================================================
-- stg_orders
-- Camada Staging: limpeza e padronização da tabela raw.orders
-- Fonte: raw.orders
-- =============================================================

with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        -- Chaves
        order_id,
        customer_id,

        -- Datas
        order_date,
        ship_date,

        -- Tempo de entrega em dias
        case
            when ship_date is not null and ship_date >= order_date
            then (ship_date - order_date)::integer
            else null
        end                                         as days_to_ship,

        -- Atributos do pedido
        lower(trim(status))                         as order_status,
        lower(trim(channel))                        as sales_channel,
        initcap(trim(region))                       as region,

        -- Flag de pedido cancelado
        case when lower(trim(status)) = 'cancelled' then true else false end as is_cancelled,

        created_at

    from source
    where order_id is not null
      and customer_id is not null
      and order_date is not null
)

select * from renamed
