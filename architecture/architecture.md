# Arquitetura — RetailCorp Corporate Data Warehouse

## Visão Geral

A arquitetura segue o padrão **Medallion Architecture** adaptado para bancos relacionais:

```
Sources → Raw → Staging → Intermediate → Marts (Star Schema) → BI
```

Cada camada tem uma responsabilidade clara e é materializada de forma diferente no PostgreSQL.

---

## Descrição de Cada Bloco

### 1. Sources (Fontes de Dados)

| Componente | Descrição |
|---|---|
| `CSV Files (dbt seeds)` | Dados de exemplo controlados por versão, carregados via `dbt seed` |
| `OLTP Simulator` | Script Python (`generate_sample_data.py`) que simula um sistema transacional real |

**Por que:** Permite demonstrar tanto ingestão de CSVs (dbt seeds) quanto geração programática de dados em volume.

---

### 2. Raw Layer (PostgreSQL — schema `raw`)

Tabelas que espelham fielmente os dados das fontes, sem transformação. São o "estado de fato" dos dados de origem.

| Tabela | Descrição |
|---|---|
| `raw.customers` | Cadastro de clientes (OLTP) |
| `raw.products` | Catálogo de produtos |
| `raw.orders` | Cabeçalho dos pedidos |
| `raw.order_items` | Linhas dos pedidos (itens) |

**Princípio:** Nunca modificar dados no raw. Preservar o histórico de carga.

---

### 3. dbt Staging (schema `staging` — materialized: `view`)

Responsável por **limpeza e padronização** dos dados raw. Um-para-um com as tabelas raw.

| Modelo | Transformações |
|---|---|
| `stg_customers` | Trim, lowercase email, extração de dígitos do telefone, title case cidade |
| `stg_products` | Title case categoria, cálculo de `margin_pct`, validação de preço positivo |
| `stg_orders` | Cálculo de `days_to_ship`, lowercase status, flag `is_cancelled` |
| `stg_order_items` | Cálculo de `item_total_amount`, `item_gross_amount`, `discount_amount` |

**Por que views:** Não ocupa espaço em disco. Sempre reflete os dados raw mais recentes.

---

### 4. dbt Intermediate (schema `intermediate` — materialized: `view`)

Responsável por **joins e enriquecimento** entre múltiplas entidades.

| Modelo | Descrição |
|---|---|
| `int_orders_enriched` | Join de 4 tabelas staging. Grão: 1 linha por item de pedido. Filtra cancelados. |

**Por que:** Isola a complexidade do join. A fact_sales e outros marts consomem esse modelo, não as tabelas staging diretamente.

---

### 5. dbt Marts — Star Schema (schema `marts` — materialized: `table`)

O coração do Data Warehouse. Implementa o **Star Schema** clássico de Kimball.

#### Dimensões

| Dimensão | Surrogate Key | Atributos Principais |
|---|---|---|
| `dim_customers` | `customer_sk` | nome, email, segmento, estado, data de cadastro |
| `dim_products` | `product_sk` | nome, categoria, subcategoria, preço, `margin_tier` |
| `dim_date` | `date_sk` | dia, semana, mês, trimestre, ano, `is_weekend` |

#### Fato

| Fato | Grão | Medidas |
|---|---|---|
| `fact_sales` | 1 linha por item de pedido | `quantity`, `unit_price`, `discount_pct`, `item_total_amount`, `item_gross_margin` |

#### Relatório

| Relatório | Grão | Uso |
|---|---|---|
| `rpt_sales_summary` | Dia + Categoria + Canal | Alimenta o dashboard Streamlit com KPIs pré-agregados |

**Por que tables:** Performance de leitura analítica. Queries do dashboard em milissegundos.

---

### 6. BI Layer

| Componente | URL | Descrição |
|---|---|---|
| Streamlit Dashboard | `localhost:8501` | KPIs, gráficos de barras, séries temporais, tabelas |
| dbt Docs | `localhost:8080` | Lineage graph, documentação, testes |

---

## Decisões de Arquitetura

### Por que Star Schema e não Data Vault?
- Projeto de portfólio: Star Schema é mais didático e amplamente utilizado
- Objetivo analítico bem definido (vendas)
- Não há requisito de auditoria histórica complexa (SCD Tipo 2)

### Por que PostgreSQL e não Snowflake/BigQuery?
- Gratuito e local — funciona sem conta em nuvem
- Suficiente para o volume de dados de estudo
- Fácil de substituir (apenas trocar o perfil dbt)

### Por que dbt-core e não dbt Cloud?
- Independência de conta/billing
- Demonstra habilidade de configurar dbt do zero
- Produção pode usar dbt Cloud sem mudança nos modelos

### Por que Surrogate Keys?
- Isolamento do DW da chave natural do sistema fonte
- Permite SCD Tipo 2 no futuro sem quebrar a fact_sales
- Boa prática de Kimball para dimensional modeling
