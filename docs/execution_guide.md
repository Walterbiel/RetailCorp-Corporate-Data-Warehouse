# Guia de Execução — RetailCorp DW

## Pré-requisitos

- Docker Desktop instalado e rodando
- Python 3.11+
- Git

## Passo a Passo Completo

### 1. Clonar o repositório

```bash
git clone <url-do-repositorio>
cd corporate-data-warehouse-dbt
```

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
# Edite o .env se necessário (padrões já funcionam com Docker)
```

### 3. Subir o PostgreSQL via Docker

```bash
docker-compose up -d postgres

# Verificar se está saudável
docker-compose ps
# Aguardar status "healthy"
```

### 4. Instalar dependências Python

```bash
python -m venv .venv
source .venv/bin/activate   # Linux/Mac
# ou
.venv\Scripts\activate      # Windows

pip install -r requirements.txt
```

### 5. Gerar dados de exemplo (opcional se usar seeds)

```bash
# Carrega 100 clientes, 50 produtos, 300 pedidos
python src/ingestion/generate_sample_data.py

# Ou com volume customizado
python src/ingestion/generate_sample_data.py --customers 500 --products 100 --orders 2000
```

### 6. Instalar pacotes dbt

```bash
cd dbt_project
dbt deps
```

### 7. Carregar seeds (CSVs de exemplo)

```bash
dbt seed
```

### 8. Rodar todos os modelos

```bash
dbt run
```

Saída esperada:
```
Running with dbt=1.7.0
Found 9 models, 4 seeds, 30 tests

Concurrency: 4 threads
1 of 9 START sql view model staging.stg_customers ............... OK
2 of 9 START sql view model staging.stg_products ................ OK
...
9 of 9 START sql table model marts.rpt_sales_summary ............ OK
Finished running 9 models in 5.23s.
```

### 9. Rodar testes de qualidade

```bash
dbt test
```

### 10. Gerar documentação interativa

```bash
dbt docs generate
dbt docs serve
# Abrir: http://localhost:8080
```

### 11. Rodar o dashboard

```bash
# Voltar para a raiz do projeto
cd ..

streamlit run app/streamlit_app.py
# Abrir: http://localhost:8501
```

## Executar tudo com Docker Compose

```bash
# Subir banco + dashboard
docker-compose up -d

# Ver logs
docker-compose logs -f streamlit
```

## Comandos dbt úteis

```bash
# Reexecutar apenas uma camada
dbt run --select staging
dbt run --select marts

# Modelo específico + dependências
dbt run --select +fact_sales

# Testar apenas um modelo
dbt test --select dim_customers

# Verificar compilação sem executar
dbt compile

# Limpar artefatos
dbt clean
```

## Troubleshooting

**Erro: connection refused**
```bash
# Verificar se o Postgres está rodando
docker-compose ps
docker-compose logs postgres
```

**Erro: relation "raw.customers" does not exist**
```bash
# Rodar o seed primeiro
cd dbt_project && dbt seed
```

**Erro: package not found**
```bash
cd dbt_project && dbt deps
```
