#!/usr/bin/env bash
# =============================================================
# run_pipeline.sh — Executa o pipeline dbt completo
# Útil para re-rodar após mudanças nos modelos
# Uso: ./scripts/helpers/run_pipeline.sh [--select <model>] [--test-only]
# =============================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }

SELECT=""
TEST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --select) SELECT="--select $2"; shift 2 ;;
        --test-only) TEST_ONLY=true; shift ;;
        *) shift ;;
    esac
done

cd dbt_project

if [ "$TEST_ONLY" = false ]; then
    info "Rodando modelos dbt ${SELECT}..."
    dbt run $SELECT
    log "dbt run concluído."
fi

info "Rodando testes dbt ${SELECT}..."
dbt test $SELECT
log "Todos os testes passaram."

cd ..
echo ""
log "Pipeline concluído com sucesso!"
