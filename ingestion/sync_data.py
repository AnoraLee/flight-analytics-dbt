import os
import csv
import tempfile
from pathlib import Path
import pandas as pd
import snowflake.connector
import pytds
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).resolve().parent.parent
load_dotenv(ROOT_DIR / ".env")

SQL_HOST = os.getenv("SQL_HOST", "db.xomdata.com")
SQL_PORT = int(os.getenv("SQL_PORT", "1433"))
SQL_USER = os.getenv("SQL_USER")
SQL_PASS = os.getenv("SQL_PASS")
SQL_DB = os.getenv("SQL_DB", "xomdata_dataset")

SF_USER = os.getenv("SF_USER")
SF_PASS = os.getenv("SF_PASS")
SF_ACCOUNT = os.getenv("SF_ACCOUNT")
SF_DB = os.getenv("SF_DB", "FLIGHTS_DW")
SF_SCHEMA = os.getenv("SF_SCHEMA", "RAW")
SF_WH = os.getenv("SF_WH", "COMPUTE_WH")
SF_ROLE = os.getenv("SF_ROLE", "ACCOUNTADMIN")

SKYTRAX_TABLES = [
    "airlines",
    "airports",
    "lounge_reviews",
    "seat_reviews",
    "airport_reviews",
    "airline_reviews",
]


def validate_env():
    missing = [
        k
        for k, v in {
            "SQL_USER": SQL_USER,
            "SQL_PASS": SQL_PASS,
            "SF_USER": SF_USER,
            "SF_PASS": SF_PASS,
            "SF_ACCOUNT": SF_ACCOUNT,
        }.items()
        if not v
    ]
    if missing:
        raise ValueError(
            f"Missing required environment variables in .env: {', '.join(missing)}"
        )


def sync_skytrax_to_snowflake():
    validate_env()

    sql_conn = pytds.connect(
        dsn=SQL_HOST,
        port=SQL_PORT,
        user=SQL_USER,
        password=SQL_PASS,
        database=SQL_DB,
    )

    sf_conn = snowflake.connector.connect(
        user=SF_USER,
        password=SF_PASS,
        account=SF_ACCOUNT,
        warehouse=SF_WH,
        database=SF_DB,
        schema=SF_SCHEMA,
        role=SF_ROLE,
    )

    try:
        sf_cur = sf_conn.cursor()
        sf_cur.execute(f"CREATE SCHEMA IF NOT EXISTS {SF_DB}.{SF_SCHEMA}")
        sf_cur.execute(f"USE SCHEMA {SF_DB}.{SF_SCHEMA}")

        sf_cur.execute("DROP TABLE IF EXISTS RAW_CATEGORIES;")

        sf_cur.execute("""
        CREATE OR REPLACE FILE FORMAT skytrax_csv_format
          TYPE = CSV
          FIELD_DELIMITER = ','
          FIELD_OPTIONALLY_ENCLOSED_BY = '"'
          ESCAPE_UNENCLOSED_FIELD = NONE
          PARSE_HEADER = TRUE
          NULL_IF = ('', 'NULL', 'null')
          EMPTY_FIELD_AS_NULL = TRUE;
        """)
        sf_cur.execute("CREATE OR REPLACE STAGE skytrax_stage;")

        temp_dir = tempfile.gettempdir()

        for table_name in SKYTRAX_TABLES:
            full_name = f"[skytrax].[{table_name}]"
            target_table = f"RAW_{table_name.upper()}"
            csv_path = os.path.join(temp_dir, f"{target_table}.csv")

            print(f"-> Extracting {full_name}...")
            with sql_conn.cursor() as cur:
                cur.execute(f"SELECT * FROM {full_name}")
                cols = [col[0].upper() for col in cur.description]
                rows = cur.fetchall()

            df = pd.DataFrame(rows, columns=cols)

            for col in df.select_dtypes(include=["object", "string"]).columns:
                df[col] = (
                    df[col]
                    .astype(str)
                    .str.replace("\r", " ", regex=False)
                    .str.replace("\n", " ", regex=False)
                )
                df[col] = df[col].replace({"None": None, "nan": None})

            df.to_csv(
                csv_path,
                index=False,
                encoding="utf-8",
                quoting=csv.QUOTE_MINIMAL,
                escapechar="\\",
            )

            print(f"   Loading {len(df):,} rows into Snowflake ({target_table})...")
            sf_path = csv_path.replace("\\", "/")

            sf_cur.execute(
                f"PUT 'file://{sf_path}' @skytrax_stage/{target_table}/ OVERWRITE = TRUE"
                " AUTO_COMPRESS = TRUE"
            )

            sf_cur.execute(f"""
            CREATE OR REPLACE TABLE {target_table}
            USING TEMPLATE (
                SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                FROM TABLE(
                    INFER_SCHEMA(
                        LOCATION => '@skytrax_stage/{target_table}/',
                        FILE_FORMAT => 'skytrax_csv_format'
                    )
                )
            );
            """)

            sf_cur.execute(f"""
            COPY INTO {target_table}
            FROM '@skytrax_stage/{target_table}/'
            FILE_FORMAT = (FORMAT_NAME = 'skytrax_csv_format')
            MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
            ON_ERROR = 'CONTINUE'
            PURGE = TRUE;
            """)

            if os.path.exists(csv_path):
                os.remove(csv_path)
            print(f"   [OK] Completed {target_table}\n")
    finally:
        sql_conn.close()
        sf_conn.close()


if __name__ == "__main__":
    sync_skytrax_to_snowflake()
