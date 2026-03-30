# Data Dictionary — RetailCorp DW

## dim_customers

| Coluna | Tipo | Descrição |
|---|---|---|
| `customer_sk` | VARCHAR | Surrogate key (hash MD5 do customer_id) |
| `customer_id` | VARCHAR | Natural key do sistema OLTP |
| `customer_name` | VARCHAR | Nome completo (título normalizado) |
| `email` | VARCHAR | E-mail em lowercase |
| `phone_digits` | VARCHAR | Telefone apenas com dígitos |
| `city` | VARCHAR | Cidade (title case) |
| `state_code` | VARCHAR(2) | UF em maiúsculas (SP, RJ...) |
| `country_code` | VARCHAR | País em maiúsculas |
| `customer_segment` | VARCHAR | Segmento: B2C, B2B, VIP |
| `customer_since_date` | DATE | Data de cadastro do cliente |
| `dw_loaded_at` | TIMESTAMP | Data/hora de carga no DW |

## dim_products

| Coluna | Tipo | Descrição |
|---|---|---|
| `product_sk` | VARCHAR | Surrogate key |
| `product_id` | VARCHAR | Natural key do catálogo |
| `sku` | VARCHAR | SKU em maiúsculas |
| `product_name` | VARCHAR | Nome do produto |
| `category` | VARCHAR | Categoria principal |
| `subcategory` | VARCHAR | Subcategoria |
| `brand` | VARCHAR | Marca |
| `unit_cost` | NUMERIC | Custo unitário (R$) |
| `unit_price` | NUMERIC | Preço de venda (R$) |
| `margin_pct` | NUMERIC | Margem em % = (preço - custo) / preço × 100 |
| `margin_tier` | VARCHAR | Alta Margem / Margem Média / Margem Baixa / Prejuízo |
| `is_active` | BOOLEAN | TRUE = produto ativo no catálogo |

## dim_date

| Coluna | Tipo | Descrição |
|---|---|---|
| `date_sk` | INTEGER | Surrogate key no formato YYYYMMDD |
| `full_date` | DATE | Data completa |
| `day_of_month` | INTEGER | Dia do mês (1-31) |
| `day_of_week` | INTEGER | Dia da semana (0=Domingo) |
| `day_name` | VARCHAR | Nome por extenso (Monday...) |
| `week_of_year` | INTEGER | Semana do ano (ISO) |
| `is_weekend` | BOOLEAN | TRUE para Sábado e Domingo |
| `month_number` | INTEGER | Mês (1-12) |
| `month_name` | VARCHAR | Nome do mês por extenso |
| `quarter_number` | INTEGER | Trimestre (1-4) |
| `year_number` | INTEGER | Ano |
| `year_month` | VARCHAR | Formato YYYY-MM |
| `year_quarter` | VARCHAR | Formato YYYY-Q1 |

## fact_sales

| Coluna | Tipo | Descrição |
|---|---|---|
| `sales_sk` | VARCHAR | Surrogate key da linha do fato |
| `order_item_id` | VARCHAR | Natural key do item |
| `order_id` | VARCHAR | ID do pedido (atributo degenerado) |
| `customer_sk` | VARCHAR | FK → dim_customers |
| `product_sk` | VARCHAR | FK → dim_products |
| `date_sk` | INTEGER | FK → dim_date |
| `sales_channel` | VARCHAR | Canal: online, store, phone |
| `region` | VARCHAR | Região geográfica |
| `order_status` | VARCHAR | Status: delivered, shipped |
| `quantity` | INTEGER | Quantidade vendida |
| `unit_price` | NUMERIC | Preço unitário praticado |
| `discount_pct` | NUMERIC | Percentual de desconto |
| `discount_amount` | NUMERIC | Valor do desconto em R$ |
| `item_gross_amount` | NUMERIC | Receita bruta (sem desconto) |
| `item_total_amount` | NUMERIC | Receita líquida (com desconto) |
| `item_total_cost` | NUMERIC | Custo total do item |
| `item_gross_margin` | NUMERIC | Margem bruta em R$ |
| `days_to_ship` | INTEGER | Dias entre pedido e envio |
| `dw_loaded_at` | TIMESTAMP | Data/hora de carga |

## rpt_sales_summary

Visão agregada de `fact_sales × dim_products × dim_date`.

| Coluna | Tipo | Descrição |
|---|---|---|
| `full_date` | DATE | Data |
| `year_month` | VARCHAR | Mês (YYYY-MM) |
| `category` | VARCHAR | Categoria do produto |
| `sales_channel` | VARCHAR | Canal de venda |
| `region` | VARCHAR | Região |
| `num_orders` | INTEGER | Número de pedidos únicos |
| `num_items_sold` | INTEGER | Número de itens vendidos |
| `total_quantity` | INTEGER | Quantidade total |
| `gross_revenue` | NUMERIC | Receita bruta (R$) |
| `total_discounts` | NUMERIC | Total de descontos (R$) |
| `net_revenue` | NUMERIC | Receita líquida (R$) |
| `total_cost` | NUMERIC | Custo total (R$) |
| `gross_margin` | NUMERIC | Margem bruta (R$) |
| `avg_order_value` | NUMERIC | Ticket médio (R$) |
| `margin_pct` | NUMERIC | Margem em % |
