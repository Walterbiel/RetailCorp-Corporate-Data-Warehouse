# Guia de Ensino — RetailCorp DW

## Como Usar este Projeto em Aula

Este projeto foi estruturado para seguir uma **progressão didática natural**, do contexto de negócio até a visualização final.

---

## Ordem Ideal de Apresentação

### Bloco 1 — Contexto (10 min)
1. Abrir `docs/business_context.md`
2. Apresentar o problema: "analistas não conseguem responder perguntas de negócio"
3. Mostrar o diagrama da arquitetura: `architecture/architecture.svg`
4. Explicar as camadas: Raw → Staging → Intermediate → Marts → BI

**Ponto-chave:** "Cada camada tem responsabilidade única. Não misturamos limpeza com regra de negócio."

---

### Bloco 2 — Infraestrutura (15 min)
1. Mostrar `docker-compose.yml` — PostgreSQL + Streamlit em containers
2. Executar ao vivo:
   ```bash
   docker-compose up -d postgres
   docker-compose ps
   ```
3. Mostrar `infra/docker/postgres/init.sql` — criação dos schemas
4. Explicar os 4 schemas: `raw`, `staging`, `intermediate`, `marts`

**O que mostrar ao vivo:** `docker-compose up` e conexão com DBeaver/psql.

---

### Bloco 3 — Dados Raw (10 min)
1. Mostrar os seeds CSV em `dbt_project/seeds/`
2. Explicar a relação OLTP: customers → orders → order_items ← products
3. Rodar `dbt seed` e mostrar as tabelas no banco
4. Opcional: rodar `generate_sample_data.py` para dados em volume

**Ponto-chave:** "O raw é intocável. É o estado de origem, auditável."

---

### Bloco 4 — dbt Staging (20 min)
1. Abrir `dbt_project/models/staging/stg_customers.sql`
2. Mostrar: CTEs, renaming, limpeza com `trim()`, `lower()`, `initcap()`
3. Mostrar `schema.yml` com testes: `unique`, `not_null`, `accepted_values`
4. Rodar: `dbt run --select staging`
5. Rodar: `dbt test --select staging`
6. Explicar: "staging são views — sem custo de armazenamento"

**Pontos técnicos para destacar:**
- Uso de CTEs (`with source as (...)`)
- Testes declarativos no YAML
- Convenção de nomenclatura `stg_*`

---

### Bloco 5 — dbt Intermediate (15 min)
1. Abrir `int_orders_enriched.sql`
2. Mostrar o join de 4 tabelas staging
3. Explicar o conceito de "grão": 1 linha por item de pedido
4. Mostrar como pedidos cancelados são filtrados aqui (não no fato)
5. Rodar: `dbt run --select intermediate`

**Ponto-chave:** "O intermediate isola a complexidade do join. A fact não precisa saber de onde vieram os dados."

---

### Bloco 6 — Modelagem Dimensional (25 min)
1. Desenhar o Star Schema no quadro/slide
2. Abrir `dim_customers.sql` — mostrar surrogate key com `dbt_utils`
3. Abrir `dim_date.sql` — mostrar `dbt_utils.date_spine`
4. Abrir `fact_sales.sql` — mostrar as foreign keys e medidas
5. Explicar: "o grão da fact é o item de pedido, não o pedido inteiro"
6. Rodar: `dbt run --select marts`
7. Mostrar `schema.yml` com relationship tests

**Perguntas que alunos fazem:**
- "Por que surrogate key e não usar o ID do sistema?"
  → Porque o DW deve ser independente do sistema fonte. Se o ID mudar no OLTP, o DW não quebra.
- "Por que dim_date não vem de uma fonte?"
  → É gerada pelo `date_spine` — sempre completa, sem gaps, controlada.
- "SCD Tipo 2 seria possível aqui?"
  → Sim! Com snapshots dbt seria a próxima evolução natural.

---

### Bloco 7 — dbt Docs (10 min)
1. Rodar `dbt docs generate && dbt docs serve`
2. Abrir http://localhost:8080
3. Mostrar o **lineage graph** (grafo de dependências)
4. Clicar em `fact_sales` — mostrar parents e children
5. Mostrar a documentação de colunas gerada do schema.yml

**Ponto-chave:** "Isso é o que separa um projeto amador de um corporativo: documentação e linhagem."

---

### Bloco 8 — Dashboard (15 min)
1. Abrir `app/streamlit_app.py`
2. Mostrar a query que lê de `marts.rpt_sales_summary`
3. Rodar: `streamlit run app/streamlit_app.py`
4. Navegar pelo dashboard ao vivo
5. Mostrar filtros funcionando
6. Alterar um dado no banco → re-rodar `dbt run` → refresh dashboard

**O que deixar pré-pronto:**
- Docker e banco já rodando
- `dbt run` já executado
- Dados já carregados

---

## Sugestões de Exercícios para Alunos

### Básico
- Adicionar um campo novo em `stg_customers` (ex: `email_domain`)
- Criar um teste customizado em `schema.yml`
- Filtrar apenas clientes do segmento VIP na `dim_customers`

### Intermediário
- Criar um novo modelo `rpt_top_customers.sql` que rankeia clientes por receita mensal
- Adicionar a coluna `is_weekend` na `fact_sales`
- Criar uma `dim_region` separada

### Avançado
- Implementar SCD Tipo 2 em `dim_customers` usando dbt snapshots
- Adicionar uma nova fonte (ex: campanhas de marketing) e criar `fact_marketing`
- Criar um dbt macro para formatação de valores monetários

---

## Roteiro para Live/Gravação (90 min)

| Tempo | Conteúdo |
|---|---|
| 0-10 min | Contexto de negócio + problema |
| 10-25 min | Arquitetura + infraestrutura Docker |
| 25-40 min | Raw layer + dbt seed |
| 40-60 min | dbt Staging + testes |
| 60-75 min | Dimensional modeling + fact_sales |
| 75-85 min | dbt Docs + lineage |
| 85-90 min | Dashboard Streamlit ao vivo |
