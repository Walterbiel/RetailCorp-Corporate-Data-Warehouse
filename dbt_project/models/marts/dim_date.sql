-- =============================================================
-- dim_date
-- Dimensão de datas: calendário completo de 2022 a 2026
-- Grão: 1 linha por dia
-- =============================================================

with date_spine as (
    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2022-01-01' as date)",
            end_date="cast('2026-12-31' as date)"
        )
    }}
),

final as (
    select
        -- Surrogate key no formato YYYYMMDD (integer)
        cast(to_char(date_day, 'YYYYMMDD') as integer)  as date_sk,

        date_day                                         as full_date,

        -- Atributos de dia
        extract(day from date_day)::integer              as day_of_month,
        extract(dow from date_day)::integer              as day_of_week,       -- 0=Sunday
        to_char(date_day, 'Day')                         as day_name,
        to_char(date_day, 'Dy')                          as day_name_short,

        -- Atributos de semana
        extract(week from date_day)::integer             as week_of_year,
        case when extract(dow from date_day) in (0, 6) then true else false end as is_weekend,

        -- Atributos de mês
        extract(month from date_day)::integer            as month_number,
        to_char(date_day, 'Month')                       as month_name,
        to_char(date_day, 'Mon')                         as month_name_short,

        -- Atributos de trimestre
        extract(quarter from date_day)::integer          as quarter_number,
        'Q' || extract(quarter from date_day)::text      as quarter_name,

        -- Atributos de ano
        extract(year from date_day)::integer             as year_number,

        -- Chaves compostas úteis para agrupamentos
        to_char(date_day, 'YYYY-MM')                     as year_month,
        extract(year from date_day)::text || '-Q' ||
            extract(quarter from date_day)::text         as year_quarter

    from date_spine
)

select * from final
