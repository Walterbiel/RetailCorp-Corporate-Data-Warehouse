"""
generate_sample_data.py — Gerador de dados simulados para o RetailCorp DW
Popula as tabelas raw com dados realistas usando Faker

Uso:
    python src/ingestion/generate_sample_data.py
    python src/ingestion/generate_sample_data.py --customers 200 --orders 500
"""

import argparse
import logging
import uuid
import random
from datetime import date, timedelta

import pandas as pd
from faker import Faker
from faker.providers import address, company, internet, phone_number

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))
from src.utils.db_utils import get_engine, execute_sql_file

logging.basicConfig(level=logging.INFO, format="%(asctime)s — %(levelname)s — %(message)s")
logger = logging.getLogger(__name__)

fake = Faker("pt_BR")
random.seed(42)

# Parâmetros de domínio de negócio
SEGMENTS     = ["B2C", "B2B", "VIP"]
SEG_WEIGHTS  = [0.65, 0.25, 0.10]
CHANNELS     = ["online", "store", "phone"]
CHAN_WEIGHTS  = [0.60, 0.25, 0.15]
REGIONS      = ["Sudeste", "Sul", "Nordeste", "Norte", "Centro-Oeste"]
ORDER_STATUS = ["delivered", "delivered", "delivered", "shipped", "cancelled"]  # peso por repetição

CATEGORIES   = {
    "Eletrônicos":  ["Computadores", "Celulares", "Monitores", "Periféricos", "Wearables", "Acessórios"],
    "Vestuário":    ["Camisas", "Calças", "Calçados", "Bolsas"],
    "Alimentos":    ["Grãos", "Bebidas", "Óleos", "Suplementos"],
}

BRANDS = {
    "Eletrônicos": ["TechBrand", "MobileTech", "VisionTech", "SoundMax", "TimeTech", "ErgoTech"],
    "Vestuário":   ["StyleCorp", "DenimPro", "SportFit", "CarryOn"],
    "Alimentos":   ["NaturalFood", "CaféMundo", "OliveGold", "FitNutrition"],
}


def generate_customers(n: int) -> pd.DataFrame:
    logger.info(f"Generating {n} customers...")
    rows = []
    for _ in range(n):
        state = random.choice(["SP", "RJ", "MG", "RS", "PR", "SC", "BA", "CE", "GO", "AM"])
        rows.append({
            "customer_id": str(uuid.uuid4()),
            "full_name":   fake.name(),
            "email":       fake.email(),
            "phone":       fake.phone_number(),
            "city":        fake.city(),
            "state":       state,
            "country":     "Brazil",
            "segment":     random.choices(SEGMENTS, weights=SEG_WEIGHTS)[0],
            "created_at":  fake.date_between(start_date="-3y", end_date="-6m"),
            "updated_at":  fake.date_between(start_date="-6m", end_date="today"),
        })
    return pd.DataFrame(rows)


def generate_products(n: int) -> pd.DataFrame:
    logger.info(f"Generating {n} products...")
    rows = []
    for i in range(n):
        category    = random.choice(list(CATEGORIES.keys()))
        subcategory = random.choice(CATEGORIES[category])
        brand       = random.choice(BRANDS[category])
        cost        = round(random.uniform(20, 3000), 2)
        margin      = random.uniform(0.20, 0.70)
        price       = round(cost * (1 + margin), 2)
        rows.append({
            "product_id":   str(uuid.uuid4()),
            "product_name": f"{brand} {subcategory} {fake.word().capitalize()} {random.randint(1, 99)}",
            "category":     category,
            "subcategory":  subcategory,
            "brand":        brand,
            "unit_cost":    cost,
            "unit_price":   price,
            "sku":          f"SKU-{category[:3].upper()}-{i+1:04d}",
            "is_active":    random.choices([True, False], weights=[0.90, 0.10])[0],
            "created_at":   fake.date_between(start_date="-3y", end_date="-3m"),
        })
    return pd.DataFrame(rows)


def generate_orders(customers_df: pd.DataFrame, n: int) -> pd.DataFrame:
    logger.info(f"Generating {n} orders...")
    customer_ids = customers_df["customer_id"].tolist()
    rows = []
    for _ in range(n):
        order_date = fake.date_between(start_date="-18m", end_date="today")
        status     = random.choice(ORDER_STATUS)
        ship_date  = None
        if status in ("shipped", "delivered"):
            ship_date = order_date + timedelta(days=random.randint(1, 7))
        rows.append({
            "order_id":    str(uuid.uuid4()),
            "customer_id": random.choice(customer_ids),
            "order_date":  order_date,
            "ship_date":   ship_date,
            "status":      status,
            "channel":     random.choices(CHANNELS, weights=CHAN_WEIGHTS)[0],
            "region":      random.choice(REGIONS),
            "created_at":  order_date,
        })
    return pd.DataFrame(rows)


def generate_order_items(orders_df: pd.DataFrame, products_df: pd.DataFrame) -> pd.DataFrame:
    logger.info("Generating order items...")
    product_ids = products_df["product_id"].tolist()
    rows = []
    for _, order in orders_df.iterrows():
        num_items = random.choices([1, 2, 3, 4], weights=[0.50, 0.30, 0.15, 0.05])[0]
        chosen_products = random.sample(product_ids, min(num_items, len(product_ids)))
        for product_id in chosen_products:
            price = float(
                products_df.loc[products_df["product_id"] == product_id, "unit_price"].values[0]
            )
            rows.append({
                "order_item_id": str(uuid.uuid4()),
                "order_id":      order["order_id"],
                "product_id":    product_id,
                "quantity":      random.randint(1, 5),
                "unit_price":    round(price * random.uniform(0.95, 1.05), 2),
                "discount_pct":  random.choices([0, 5, 10, 15, 20], weights=[0.50, 0.20, 0.15, 0.10, 0.05])[0],
                "created_at":    order["order_date"],
            })
    return pd.DataFrame(rows)


def load_to_postgres(df: pd.DataFrame, schema: str, table: str, engine) -> None:
    logger.info(f"Loading {len(df)} rows → {schema}.{table}")
    df.to_sql(
        name=table,
        schema=schema,
        con=engine,
        if_exists="append",
        index=False,
        method="multi",
        chunksize=500,
    )


def main(n_customers: int = 100, n_products: int = 50, n_orders: int = 300):
    engine = get_engine()

    # Criar schemas e tabelas raw se não existirem
    sql_path = os.path.join(os.path.dirname(__file__), "../../infra/sql/create_raw_tables.sql")
    if os.path.exists(sql_path):
        execute_sql_file(sql_path)

    customers_df  = generate_customers(n_customers)
    products_df   = generate_products(n_products)
    orders_df     = generate_orders(customers_df, n_orders)
    order_items_df = generate_order_items(orders_df, products_df)

    load_to_postgres(customers_df,   "raw", "customers",   engine)
    load_to_postgres(products_df,    "raw", "products",    engine)
    load_to_postgres(orders_df,      "raw", "orders",      engine)
    load_to_postgres(order_items_df, "raw", "order_items", engine)

    logger.info("Data generation complete!")
    logger.info(f"  Customers:   {len(customers_df)}")
    logger.info(f"  Products:    {len(products_df)}")
    logger.info(f"  Orders:      {len(orders_df)}")
    logger.info(f"  Order Items: {len(order_items_df)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate sample data for RetailCorp DW")
    parser.add_argument("--customers", type=int, default=100)
    parser.add_argument("--products",  type=int, default=50)
    parser.add_argument("--orders",    type=int, default=300)
    args = parser.parse_args()
    main(args.customers, args.products, args.orders)
