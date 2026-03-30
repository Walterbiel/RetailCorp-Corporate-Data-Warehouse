-- =============================================================
-- RetailCorp Data Warehouse — Inicialização do banco PostgreSQL
-- Executado automaticamente pelo Docker na primeira inicialização
-- =============================================================

-- Schema para dados brutos (Raw Layer)
CREATE SCHEMA IF NOT EXISTS raw;

-- Schema para camada de staging (dbt)
CREATE SCHEMA IF NOT EXISTS staging;

-- Schema para camada intermediária (dbt)
CREATE SCHEMA IF NOT EXISTS intermediate;

-- Schema para data marts / dimensional model (dbt)
CREATE SCHEMA IF NOT EXISTS marts;

-- Tabelas raw — espelham os dados das fontes transacionais

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id     VARCHAR(36)  PRIMARY KEY,
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(200),
    phone           VARCHAR(50),
    city            VARCHAR(100),
    state           VARCHAR(50),
    country         VARCHAR(50)  DEFAULT 'Brazil',
    segment         VARCHAR(50),  -- 'B2C', 'B2B', 'VIP'
    created_at      TIMESTAMP    DEFAULT NOW(),
    updated_at      TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id      VARCHAR(36)  PRIMARY KEY,
    product_name    VARCHAR(300) NOT NULL,
    category        VARCHAR(100),
    subcategory     VARCHAR(100),
    brand           VARCHAR(100),
    unit_cost       NUMERIC(10,2),
    unit_price      NUMERIC(10,2),
    sku             VARCHAR(50),
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id        VARCHAR(36)  PRIMARY KEY,
    customer_id     VARCHAR(36)  NOT NULL REFERENCES raw.customers(customer_id),
    order_date      DATE         NOT NULL,
    ship_date       DATE,
    status          VARCHAR(50),  -- 'pending', 'shipped', 'delivered', 'cancelled'
    channel         VARCHAR(50),  -- 'online', 'store', 'phone'
    region          VARCHAR(50),
    created_at      TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_item_id   VARCHAR(36)  PRIMARY KEY,
    order_id        VARCHAR(36)  NOT NULL REFERENCES raw.orders(order_id),
    product_id      VARCHAR(36)  NOT NULL REFERENCES raw.products(product_id),
    quantity        INTEGER      NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,
    discount_pct    NUMERIC(5,2)  DEFAULT 0.0,
    created_at      TIMESTAMP    DEFAULT NOW()
);
