#!/usr/bin/env bash
set -euo pipefail

STEP="${1:-transform}"

if [ -f ".env" ]; then
    set -a
    source <(grep -v '^#' .env | sed 's/\r$//')
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

if [ -f "env_dbt/Scripts/python.exe" ]; then
    PYTHON_BIN="env_dbt/Scripts/python.exe"
    DBT_BIN="env_dbt/Scripts/dbt.exe"
elif [ -f ".venv/bin/python" ]; then
    PYTHON_BIN=".venv/bin/python"
    DBT_BIN=".venv/bin/dbt"
else
    PYTHON_BIN="python"
    DBT_BIN="dbt"
fi

if [ "$STEP" == "all" ] || [ "$STEP" == "ingest" ]; then
    "$PYTHON_BIN" ingestion/sync_data.py
fi

if [ "$STEP" == "all" ] || [ "$STEP" == "transform" ]; then
    "$DBT_BIN" run --project-dir transform --profiles-dir transform
fi

if [ "$STEP" == "all" ] || [ "$STEP" == "transform" ] || [ "$STEP" == "test" ]; then
    "$DBT_BIN" test --project-dir transform --profiles-dir transform
fi
