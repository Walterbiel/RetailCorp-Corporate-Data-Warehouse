"""
streamlit_app.py — Dashboard Analítico RetailCorp
Lê diretamente do schema marts (dbt output) e exibe KPIs de vendas
"""

import os
import sys

import streamlit as st
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from src.utils.db_utils import run_query

load_dotenv()

# ─────────────────────────────────────────────
# Configuração da página
# ─────────────────────────────────────────────
st.set_page_config(
    page_title="RetailCorp Analytics",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.title("📊 RetailCorp — Sales Analytics Dashboard")
st.markdown("*Powered by PostgreSQL + dbt + Streamlit*")

# ─────────────────────────────────────────────
# Sidebar: filtros
# ─────────────────────────────────────────────
with st.sidebar:
    st.header("Filtros")

    years_df = run_query("SELECT DISTINCT year_number FROM marts.rpt_sales_summary ORDER BY year_number DESC")
    year_options = years_df["year_number"].tolist() if not years_df.empty else [2024]
    selected_year = st.selectbox("Ano", year_options, index=0)

    categories_df = run_query("SELECT DISTINCT category FROM marts.rpt_sales_summary ORDER BY category")
    cat_options = ["Todas"] + categories_df["category"].tolist()
    selected_cat = st.selectbox("Categoria", cat_options)

    channels_df = run_query("SELECT DISTINCT sales_channel FROM marts.rpt_sales_summary ORDER BY sales_channel")
    chan_options = ["Todos"] + channels_df["sales_channel"].tolist()
    selected_channel = st.selectbox("Canal de Venda", chan_options)

# ─────────────────────────────────────────────
# Queries com filtros aplicados
# ─────────────────────────────────────────────
cat_filter     = f"AND category = '{selected_cat}'" if selected_cat != "Todas" else ""
channel_filter = f"AND sales_channel = '{selected_channel}'" if selected_channel != "Todos" else ""
base_filter    = f"WHERE year_number = {selected_year} {cat_filter} {channel_filter}"

# KPIs gerais
kpi_df = run_query(f"""
    SELECT
        SUM(net_revenue)    AS total_revenue,
        SUM(num_orders)     AS total_orders,
        AVG(avg_order_value) AS avg_ticket,
        SUM(gross_margin)   AS total_margin,
        SUM(total_discounts) AS total_discounts
    FROM marts.rpt_sales_summary
    {base_filter}
""")

# ─────────────────────────────────────────────
# KPI Cards
# ─────────────────────────────────────────────
if not kpi_df.empty and kpi_df["total_revenue"].iloc[0]:
    r = kpi_df.iloc[0]
    col1, col2, col3, col4, col5 = st.columns(5)
    col1.metric("💰 Receita Líquida",    f"R$ {r['total_revenue']:,.0f}")
    col2.metric("🛒 Total de Pedidos",   f"{int(r['total_orders']):,}")
    col3.metric("🎫 Ticket Médio",       f"R$ {r['avg_ticket']:,.0f}")
    col4.metric("📈 Margem Bruta",       f"R$ {r['total_margin']:,.0f}")
    col5.metric("🏷️ Total Descontos",   f"R$ {r['total_discounts']:,.0f}")
else:
    st.warning("Nenhum dado encontrado para os filtros selecionados. Execute o pipeline dbt primeiro.")
    st.stop()

st.divider()

# ─────────────────────────────────────────────
# Linha 1: Receita por Mês + Receita por Categoria
# ─────────────────────────────────────────────
col_left, col_right = st.columns(2)

with col_left:
    st.subheader("📅 Receita Mensal")
    monthly_df = run_query(f"""
        SELECT year_month, SUM(net_revenue) AS revenue
        FROM marts.rpt_sales_summary
        {base_filter}
        GROUP BY year_month
        ORDER BY year_month
    """)
    if not monthly_df.empty:
        fig = px.line(
            monthly_df, x="year_month", y="revenue",
            markers=True, title="Evolução da Receita Líquida Mensal",
            labels={"year_month": "Mês", "revenue": "Receita (R$)"},
            color_discrete_sequence=["#2563EB"],
        )
        fig.update_layout(showlegend=False)
        st.plotly_chart(fig, use_container_width=True)

with col_right:
    st.subheader("🗂️ Receita por Categoria")
    cat_df = run_query(f"""
        SELECT category, SUM(net_revenue) AS revenue
        FROM marts.rpt_sales_summary
        {base_filter}
        GROUP BY category
        ORDER BY revenue DESC
    """)
    if not cat_df.empty:
        fig = px.bar(
            cat_df, x="revenue", y="category", orientation="h",
            title="Receita por Categoria",
            labels={"revenue": "Receita (R$)", "category": "Categoria"},
            color="revenue", color_continuous_scale="Blues",
        )
        st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────────
# Linha 2: Top 10 Produtos + Canal de Venda
# ─────────────────────────────────────────────
col_left2, col_right2 = st.columns(2)

with col_left2:
    st.subheader("🏆 Top 10 Produtos por Receita")
    top_products_df = run_query(f"""
        SELECT
            p.product_name,
            p.category,
            SUM(f.item_total_amount) AS revenue
        FROM marts.fact_sales f
        INNER JOIN marts.dim_products p ON f.product_sk = p.product_sk
        INNER JOIN marts.dim_date d ON f.date_sk = d.date_sk
        WHERE d.year_number = {selected_year}
        {f"AND p.category = '{selected_cat}'" if selected_cat != "Todas" else ""}
        {f"AND f.sales_channel = '{selected_channel}'" if selected_channel != "Todos" else ""}
        GROUP BY p.product_name, p.category
        ORDER BY revenue DESC
        LIMIT 10
    """)
    if not top_products_df.empty:
        fig = px.bar(
            top_products_df, x="revenue", y="product_name", orientation="h",
            color="category",
            title="Top 10 Produtos — Receita Líquida",
            labels={"revenue": "Receita (R$)", "product_name": "Produto"},
        )
        fig.update_layout(yaxis=dict(autorange="reversed"))
        st.plotly_chart(fig, use_container_width=True)

with col_right2:
    st.subheader("📡 Receita por Canal de Venda")
    channel_df = run_query(f"""
        SELECT sales_channel, SUM(net_revenue) AS revenue
        FROM marts.rpt_sales_summary
        {base_filter}
        GROUP BY sales_channel
        ORDER BY revenue DESC
    """)
    if not channel_df.empty:
        fig = px.pie(
            channel_df, values="revenue", names="sales_channel",
            title="Distribuição de Receita por Canal",
            color_discrete_sequence=px.colors.qualitative.Set2,
            hole=0.35,
        )
        st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────────
# Linha 3: Margem por Categoria + Desempenho Regional
# ─────────────────────────────────────────────
col_left3, col_right3 = st.columns(2)

with col_left3:
    st.subheader("💹 Margem por Categoria")
    margin_df = run_query(f"""
        SELECT category, ROUND(AVG(margin_pct), 2) AS avg_margin
        FROM marts.rpt_sales_summary
        {base_filter}
        GROUP BY category
        ORDER BY avg_margin DESC
    """)
    if not margin_df.empty:
        fig = px.bar(
            margin_df, x="category", y="avg_margin",
            title="Margem Média (%) por Categoria",
            labels={"avg_margin": "Margem (%)", "category": "Categoria"},
            color="avg_margin", color_continuous_scale="RdYlGn",
        )
        st.plotly_chart(fig, use_container_width=True)

with col_right3:
    st.subheader("🗺️ Receita por Região")
    region_df = run_query(f"""
        SELECT region, SUM(net_revenue) AS revenue
        FROM marts.rpt_sales_summary
        {base_filter}
        GROUP BY region
        ORDER BY revenue DESC
    """)
    if not region_df.empty:
        fig = px.bar(
            region_df, x="region", y="revenue",
            title="Receita por Região",
            labels={"revenue": "Receita (R$)", "region": "Região"},
            color="revenue", color_continuous_scale="Purples",
        )
        st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────────
# Tabela: Top Clientes
# ─────────────────────────────────────────────
st.subheader("👥 Top 15 Clientes por Receita")
top_customers_df = run_query(f"""
    SELECT
        c.customer_name,
        c.customer_segment,
        c.state_code,
        COUNT(DISTINCT f.order_id)           AS num_orders,
        ROUND(SUM(f.item_total_amount), 2)   AS total_spent,
        ROUND(AVG(f.item_total_amount), 2)   AS avg_item_value
    FROM marts.fact_sales f
    INNER JOIN marts.dim_customers c ON f.customer_sk = c.customer_sk
    INNER JOIN marts.dim_date d ON f.date_sk = d.date_sk
    WHERE d.year_number = {selected_year}
    GROUP BY c.customer_name, c.customer_segment, c.state_code
    ORDER BY total_spent DESC
    LIMIT 15
""")
if not top_customers_df.empty:
    st.dataframe(
        top_customers_df.rename(columns={
            "customer_name": "Cliente",
            "customer_segment": "Segmento",
            "state_code": "Estado",
            "num_orders": "Pedidos",
            "total_spent": "Receita Total (R$)",
            "avg_item_value": "Valor Médio/Item (R$)",
        }),
        use_container_width=True,
        hide_index=True,
    )

# ─────────────────────────────────────────────
# Footer
# ─────────────────────────────────────────────
st.divider()
st.caption("RetailCorp Analytics Platform · PostgreSQL + dbt + Streamlit · Portfólio de Engenharia de Dados")
