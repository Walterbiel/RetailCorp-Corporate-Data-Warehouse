-- =============================================================
-- RetailCorp DW — DDL das tabelas Raw (para execução manual)
-- Use este arquivo se não estiver usando Docker
-- =============================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS marts;

DROP TABLE IF EXISTS raw.order_items CASCADE;
DROP TABLE IF EXISTS raw.orders CASCADE;
DROP TABLE IF EXISTS raw.products CASCADE;
DROP TABLE IF EXISTS raw.customers CASCADE;

CREATE TABLE raw.customers (
    customer_id  VARCHAR(36)  PRIMARY KEY,
    full_name    VARCHAR(200) NOT NULL,
    email        VARCHAR(200),
    phone        VARCHAR(50),
    city         VARCHAR(100),
    state        VARCHAR(50),
    country      VARCHAR(50)  DEFAULT 'Brazil',
    segment      VARCHAR(50),
    created_at   TIMESTAMP    DEFAULT NOW(),
    updated_at   TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE raw.products (
    product_id   VARCHAR(36)   PRIMARY KEY,
    product_name VARCHAR(300)  NOT NULL,
    category     VARCHAR(100),
    subcategory  VARCHAR(100),
    brand        VARCHAR(100),
    unit_cost    NUMERIC(10,2),
    unit_price   NUMERIC(10,2),
    sku          VARCHAR(50),
    is_active    BOOLEAN       DEFAULT TRUE,
    created_at   TIMESTAMP     DEFAULT NOW()
);

CREATE TABLE raw.orders (
    order_id     VARCHAR(36)  PRIMARY KEY,
    customer_id  VARCHAR(36)  NOT NULL REFERENCES raw.customers(customer_id),
    order_date   DATE         NOT NULL,
    ship_date    DATE,
    status       VARCHAR(50),
    channel      VARCHAR(50),
    region       VARCHAR(50),
    created_at   TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE raw.order_items (
    order_item_id VARCHAR(36)   PRIMARY KEY,
    order_id      VARCHAR(36)   NOT NULL REFERENCES raw.orders(order_id),
    product_id    VARCHAR(36)   NOT NULL REFERENCES raw.products(product_id),
    quantity      INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL,
    discount_pct  NUMERIC(5,2)  DEFAULT 0.0,
    created_at    TIMESTAMP     DEFAULT NOW()
);
