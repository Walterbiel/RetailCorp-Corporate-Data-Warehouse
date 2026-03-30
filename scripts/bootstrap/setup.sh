#!/usr/bin/env bash
# =============================================================
# setup.sh — Bootstrap completo do RetailCorp DW
# Executa todos os passos do zero: infra → dados → dbt → dashboard
# Uso: chmod +x scripts/bootstrap/setup.sh && ./scripts/bootstrap/setup.sh
# =============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║      RetailCorp Data Warehouse — Bootstrap           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Verificar pré-requisitos
command -v docker      >/dev/null 2>&1 || fail "Docker não encontrado. Instale: https://docs.docker.com/get-docker/"
command -v python3     >/dev/null 2>&1 || fail "Python 3 não encontrado."
command -v pip         >/dev/null 2>&1 || fail "pip não encontrado."

# Copiar .env se não existir
if [ ! -f ".env" ]; then
    cp .env.example .env
    warn ".env criado a partir do .env.example. Verifique as variáveis se necessário."
fi

# Subir PostgreSQL
info "Subindo PostgreSQL via Docker..."
docker-compose up -d postgres

info "Aguardando PostgreSQL ficar pronto..."
for i in {1..20}; do
    if docker-compose exec -T postgres pg_isready -U dw_user -d retailcorp_dw >/dev/null 2>&1; then
        log "PostgreSQL pronto!"
        break
    fi
    sleep 2
    if [ $i -eq 20 ]; then
        fail "PostgreSQL não respondeu após 40 segundos. Verifique: docker-compose logs postgres"
    fi
done

# Instalar dependências Python
info "Instalando dependências Python..."
pip install -r requirements.txt -q
log "Dependências instaladas."

# Gerar dados de exemplo
info "Gerando dados de exemplo..."
python3 src/ingestion/generate_sample_data.py --customers 100 --products 50 --orders 300
log "Dados gerados."

# Instalar pacotes dbt
info "Instalando pacotes dbt..."
cd dbt_project
dbt deps --quiet
log "dbt deps OK."

# Rodar seeds
info "Carregando seeds CSV..."
dbt seed --quiet
log "Seeds carregados."

# Rodar pipeline dbt
info "Executando pipeline dbt (staging → intermediate → marts)..."
dbt run
log "Modelos dbt executados."

# Rodar testes
info "Executando testes de qualidade..."
dbt test
log "Todos os testes passaram!"

cd ..

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║              ✅  Setup Completo!                      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Dashboard Streamlit:  streamlit run app/streamlit_app.py  ║"
echo "║  dbt Docs:             cd dbt_project && dbt docs serve    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
