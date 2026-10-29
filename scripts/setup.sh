#!/usr/bin/env bash
set -euo pipefail

if [ -f "env_dbt/Scripts/python.exe" ]; then
    env_dbt/Scripts/python.exe -m pip install -r requirements.txt
    DBT_BIN="env_dbt/Scripts/dbt.exe"
else
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    DBT_BIN="dbt"
fi

"$DBT_BIN" deps --project-dir transform --profiles-dir transform

if [ ! -f ".env" ]; then
    cp .env.example .env
fi
