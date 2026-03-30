# Contexto de Negócio — RetailCorp Analytics Platform

## A Empresa

A **RetailCorp** é uma empresa fictícia de varejo com:
- 500+ SKUs ativos em 3 grandes categorias (Eletrônicos, Vestuário, Alimentos)
- Operações em 5 regiões do Brasil
- 3 canais de venda: online, loja física, telefone
- 3 segmentos de clientes: B2C, B2B e VIP

## O Problema

O sistema OLTP (transacional) da empresa registra pedidos com eficiência, mas:

1. **Relatórios lentos:** Queries analíticas com múltiplos JOINs travavam o banco de produção
2. **Sem histórico consolidado:** Cada analista escrevia suas próprias queries, com resultados inconsistentes
3. **Sem qualidade de dados:** Campos com formatos diferentes, nulls inesperados
4. **Sem documentação:** Ninguém sabia o que cada campo significava
5. **Sem self-service:** O time de BI dependia de TI para cada nova análise

## A Solução

Construção de um **Data Warehouse Corporativo** com:
- **Camada raw:** Dados brutos preservados para auditoria
- **Pipeline dbt:** Transformações versionadas, testadas e documentadas em SQL
- **Star Schema:** Modelo dimensional otimizado para leitura analítica
- **Dashboard Streamlit:** Self-service para o time de negócio

## Valor Gerado

| Antes | Depois |
|---|---|
| Query analítica: 30-120s | Query no mart: < 1s |
| 5 versões de KPIs diferentes | 1 fonte de verdade (fact_sales) |
| Zero testes de dados | 25+ testes automáticos com dbt |
| Zero documentação | Lineage graph + data dictionary completo |
| Analista dependente de TI | Self-service via Streamlit |

## Perguntas de Negócio Respondidas

- Qual produto gerou mais receita nos últimos 3 meses?
- Qual categoria tem maior margem de contribuição?
- Quais clientes VIP compraram menos de 2x no último trimestre?
- Como a receita evolui semana a semana por canal?
- Qual região tem maior ticket médio?
- Qual dia da semana tem mais vendas?
