.PHONY: setup ingest transform test all

PYTHON = ./env_dbt/Scripts/python.exe
DBT = ./env_dbt/Scripts/dbt.exe

setup:
	bash ./scripts/setup.sh

ingest:
	bash ./run_pipeline.sh ingest

transform:
	bash ./run_pipeline.sh transform

test:
	bash ./run_pipeline.sh test

all:
	bash ./run_pipeline.sh all
