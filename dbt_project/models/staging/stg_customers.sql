-- =============================================================
-- stg_customers
-- Camada Staging: limpeza e padronização da tabela raw.customers
-- Fonte: raw.customers (seed CSV ou tabela raw do OLTP)
-- =============================================================

with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        -- Chaves
        customer_id,

        -- Atributos pessoais com limpeza
        trim(full_name)                         as customer_name,
        lower(trim(email))                      as email,
        regexp_replace(phone, '[^0-9]', '', 'g') as phone_digits,

        -- Localização
        initcap(trim(city))                     as city,
        upper(trim(state))                      as state_code,
        upper(trim(country))                    as country_code,

        -- Segmentação
        upper(trim(segment))                    as customer_segment,

        -- Metadados
        created_at::date                        as customer_since_date,
        updated_at

    from source
    where customer_id is not null
      and full_name is not null
)

select * from renamed
