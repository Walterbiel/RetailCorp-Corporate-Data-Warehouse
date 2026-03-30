"""
db_utils.py — Utilitários de conexão com o PostgreSQL
Usado pelo gerador de dados e pelo dashboard Streamlit
"""

import os
import logging
from contextlib import contextmanager

import psycopg2
from psycopg2 import pool
from sqlalchemy import create_engine, text
import pandas as pd
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)


def get_connection_string() -> str:
    """Monta a connection string a partir das variáveis de ambiente."""
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db   = os.getenv("POSTGRES_DB",   "retailcorp_dw")
    user = os.getenv("POSTGRES_USER", "dw_user")
    pwd  = os.getenv("POSTGRES_PASSWORD", "dw_password")
    return f"postgresql://{user}:{pwd}@{host}:{port}/{db}"


def get_engine():
    """Retorna um engine SQLAlchemy com pool de conexões."""
    return create_engine(
        get_connection_string(),
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,   # verifica conexão antes de usar
    )


@contextmanager
def get_psycopg2_conn():
    """Context manager para conexão psycopg2 (baixo nível)."""
    conn = psycopg2.connect(get_connection_string())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def run_query(sql: str, params: dict = None) -> pd.DataFrame:
    """Executa uma query SQL e retorna um DataFrame Pandas."""
    engine = get_engine()
    with engine.connect() as conn:
        result = conn.execute(text(sql), params or {})
        return pd.DataFrame(result.fetchall(), columns=result.keys())


def execute_sql_file(filepath: str) -> None:
    """Executa um arquivo .sql no banco."""
    with open(filepath, "r", encoding="utf-8") as f:
        sql = f.read()
    with get_psycopg2_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
    logger.info(f"SQL file executed: {filepath}")


def table_exists(schema: str, table: str) -> bool:
    """Verifica se uma tabela existe no banco."""
    df = run_query(
        """
        SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = :schema
              AND table_name   = :table
        ) AS exists
        """,
        {"schema": schema, "table": table},
    )
    return bool(df["exists"].iloc[0])


def get_row_count(schema: str, table: str) -> int:
    """Retorna o número de linhas de uma tabela."""
    df = run_query(f'SELECT COUNT(*) AS cnt FROM "{schema}"."{table}"')
    return int(df["cnt"].iloc[0])
