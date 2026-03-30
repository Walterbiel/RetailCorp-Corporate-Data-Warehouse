"""
test_db_utils.py — Testes básicos dos utilitários de banco de dados
Execute com: pytest tests/
"""

import pytest
from unittest.mock import patch, MagicMock
import pandas as pd


def test_get_connection_string_defaults(monkeypatch):
    """Verifica que a connection string usa os valores padrão quando env não configurado."""
    import sys
    import os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

    for var in ["POSTGRES_HOST", "POSTGRES_PORT", "POSTGRES_DB", "POSTGRES_USER", "POSTGRES_PASSWORD"]:
        monkeypatch.delenv(var, raising=False)

    from src.utils.db_utils import get_connection_string
    conn_str = get_connection_string()

    assert "localhost" in conn_str
    assert "5432" in conn_str
    assert "retailcorp_dw" in conn_str
    assert "dw_user" in conn_str


def test_get_connection_string_from_env(monkeypatch):
    """Verifica que a connection string usa variáveis de ambiente quando configuradas."""
    monkeypatch.setenv("POSTGRES_HOST", "my-host")
    monkeypatch.setenv("POSTGRES_PORT", "5433")
    monkeypatch.setenv("POSTGRES_DB", "my-db")
    monkeypatch.setenv("POSTGRES_USER", "my-user")
    monkeypatch.setenv("POSTGRES_PASSWORD", "my-pass")

    from src.utils import db_utils
    import importlib
    importlib.reload(db_utils)

    conn_str = db_utils.get_connection_string()
    assert "my-host" in conn_str
    assert "5433" in conn_str
    assert "my-db" in conn_str


@patch("src.utils.db_utils.get_engine")
def test_run_query_returns_dataframe(mock_engine):
    """Verifica que run_query retorna um DataFrame."""
    mock_conn = MagicMock()
    mock_result = MagicMock()
    mock_result.fetchall.return_value = [(1, "test")]
    mock_result.keys.return_value = ["id", "name"]
    mock_conn.__enter__ = MagicMock(return_value=mock_conn)
    mock_conn.__exit__ = MagicMock(return_value=False)
    mock_conn.execute.return_value = mock_result
    mock_engine.return_value.connect.return_value = mock_conn

    from src.utils.db_utils import run_query
    df = run_query("SELECT 1 AS id, 'test' AS name")

    assert isinstance(df, pd.DataFrame)
    assert len(df) == 1
