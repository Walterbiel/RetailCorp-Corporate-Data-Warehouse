# Guia de Deploy — RetailCorp DW

## Opções de Deploy

| Plataforma | Custo | Dificuldade | Indicado para |
|---|---|---|---|
| **Render** | Gratuito (limitado) | Baixa | Portfólio |
| **Railway** | ~$5/mês | Baixa | Demo pessoal |
| **Azure** | Pay-as-you-go | Média | Produção |
| **Docker em VPS** | ~$5/mês (DigitalOcean) | Média | Controle total |

---

## Deploy no Render (Recomendado para Portfólio)

### 1. PostgreSQL no Render

1. Acessar render.com → New → PostgreSQL
2. Configurar:
   - Name: `retailcorp-db`
   - Region: Oregon (gratuito)
   - Plan: Free
3. Copiar a **External Database URL**

### 2. Web Service (Streamlit) no Render

1. New → Web Service → conectar ao GitHub repo
2. Configurar:
   ```
   Build Command: pip install -r requirements.txt
   Start Command: streamlit run app/streamlit_app.py --server.port=$PORT --server.address=0.0.0.0
   ```
3. Adicionar Environment Variables:
   ```
   POSTGRES_HOST=<host-do-render>
   POSTGRES_PORT=5432
   POSTGRES_DB=retailcorp_dw
   POSTGRES_USER=<user>
   POSTGRES_PASSWORD=<password>
   ```

### 3. Rodar dbt no Render (deploy manual)

```bash
# No shell do Render ou via GitHub Actions
cd dbt_project
dbt deps
dbt seed
dbt run
```

---

## Deploy no Railway

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Criar projeto
railway new

# Adicionar PostgreSQL
railway add postgresql

# Deploy da aplicação
railway up

# Configurar variáveis
railway variables set POSTGRES_HOST=... POSTGRES_PASSWORD=...
```

---

## Deploy no Azure (Produção)

### Serviços utilizados

| Serviço | Uso |
|---|---|
| Azure Database for PostgreSQL Flexible | Banco de dados |
| Azure Container Apps | Streamlit containerizado |
| Azure Container Registry | Imagem Docker |

### Passo a passo

```bash
# 1. Login Azure
az login

# 2. Criar Resource Group
az group create --name retailcorp-rg --location brazilsouth

# 3. Criar PostgreSQL
az postgres flexible-server create \
  --resource-group retailcorp-rg \
  --name retailcorp-pg \
  --admin-user dwuser \
  --admin-password YourPassword123! \
  --sku-name Standard_B1ms \
  --tier Burstable

# 4. Build e push da imagem Docker
az acr create --resource-group retailcorp-rg --name retailcorpacr --sku Basic
az acr login --name retailcorpacr
docker build -t retailcorpacr.azurecr.io/retailcorp-app:latest .
docker push retailcorpacr.azurecr.io/retailcorp-app:latest

# 5. Deploy no Container Apps
az containerapp create \
  --name retailcorp-dashboard \
  --resource-group retailcorp-rg \
  --image retailcorpacr.azurecr.io/retailcorp-app:latest \
  --target-port 8501 \
  --ingress external \
  --env-vars POSTGRES_HOST=retailcorp-pg.postgres.database.azure.com \
             POSTGRES_USER=dwuser \
             POSTGRES_PASSWORD=YourPassword123!
```

---

## GitHub Actions — CI/CD para dbt

Criar `.github/workflows/dbt_ci.yml`:

```yaml
name: dbt CI

on:
  push:
    branches: [main]
  pull_request:
    paths:
      - 'dbt_project/**'

jobs:
  dbt-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: retailcorp_dw
          POSTGRES_USER: dw_user
          POSTGRES_PASSWORD: dw_password
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install dbt-postgres==1.7.0
      - working-directory: dbt_project
        run: |
          dbt deps
          dbt seed
          dbt run
          dbt test
        env:
          POSTGRES_HOST: localhost
          POSTGRES_USER: dw_user
          POSTGRES_PASSWORD: dw_password
          POSTGRES_DB: retailcorp_dw
```

---

## Custos Estimados

| Ambiente | Custo Mensal |
|---|---|
| Render Free (portfólio) | R$ 0 |
| Railway (demo pessoal) | ~R$ 25 |
| Azure dev/test (B1ms PG + Container App) | ~R$ 80-150 |
| Azure produção (Standard_D2s PG + Container App) | ~R$ 400-800 |

**Recomendação:** Para portfólio, use Render Free. Para demonstrar produção, documente a arquitetura Azure sem necessariamente subir o ambiente.
