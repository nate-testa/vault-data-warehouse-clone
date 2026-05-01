"""
Database Loader for Aircall to EDW

Handles SQL Server connection, data loading, and load strategies
(truncate_day, append, truncate_all) for the staging table.
"""

import json
import logging
from datetime import datetime, timezone

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Engine
from sqlalchemy.types import NVARCHAR, DECIMAL, BigInteger, Integer, Boolean

from config_manager import setup_logger


# Column mapping: DDL column name -> extraction function from API call dict
# Types aligned with Aircall API docs (https://developer.aircall.io/api-references/#call-overview)
# - id: integer (Int64), sid: string, started_at/answered_at/ended_at: integer (UNIX timestamp)
# - duration: integer (seconds), archived: boolean, cost: string (DEPRECATED)
# - user/contact/number/assigned_to/transferred_by/transferred_to: object (JSON)
# - comments/tags/teams/ivr_options_selected: array (JSON)
COLUMN_MAPPING = {
    'id': lambda c: _to_str(c.get('id')),                        # API id (Int64) -> NVARCHAR
    'sid': lambda c: _to_str(c.get('sid')),                      # string
    'direct_link': lambda c: _to_str(c.get('direct_link')),      # string
    'direction': lambda c: _to_str(c.get('direction')),          # string
    'status': lambda c: _to_str(c.get('status')),                # string
    'missed_call_reason': lambda c: _to_str(c.get('missed_call_reason')),  # string
    'started_at': lambda c: c.get('started_at'),                 # integer (UNIX ts)
    'answered_at': lambda c: c.get('answered_at'),               # integer (UNIX ts)
    'ended_at': lambda c: c.get('ended_at'),                     # integer (UNIX ts)
    'duration': lambda c: c.get('duration'),                     # integer (seconds)
    'archived': lambda c: c.get('archived'),                     # boolean
    'cost': lambda c: c.get('cost'),                             # string (DEPRECATED)
    'voicemail': lambda c: _to_str(c.get('voicemail')),          # string (URL)
    'recording': lambda c: _to_str(c.get('recording')),          # string (URL)
    'asset': lambda c: _to_str(c.get('asset')),                  # string (URL)
    'raw_digits': lambda c: _to_str(c.get('raw_digits')),        # string
    'user_json': lambda c: _to_json(c.get('user')),              # object -> JSON
    'contact_json': lambda c: _to_json(c.get('contact')),        # object -> JSON
    'assigned_to_json': lambda c: _to_json(c.get('assigned_to')),       # object -> JSON
    'transferred_by_json': lambda c: _to_json(c.get('transferred_by')), # object -> JSON
    'transferred_to_json': lambda c: _to_json(c.get('transferred_to')), # object -> JSON
    'comments_json': lambda c: _to_json(c.get('comments')),      # array -> JSON
    'number_json': lambda c: _to_json(c.get('number')),          # object -> JSON
    'teams_json': lambda c: _to_json(c.get('teams')),            # array -> JSON
    'tags_json': lambda c: _to_json(c.get('tags')),              # array -> JSON
    'recording_short_url': lambda c: _to_str(c.get('recording_short_url')),  # string
    'voicemail_short_url': lambda c: _to_str(c.get('voicemail_short_url')),  # string
    'country_code_a2': lambda c: _extract_country(c),            # from number.country
    'pricing_type': lambda c: None,                              # not in API docs
    'ivr_options_selected_json': lambda c: _to_json(c.get('ivr_options_selected')),  # array -> JSON
    'create_ts': lambda c: datetime.now(timezone.utc),
}


def _to_str(value):
    if value is None:
        return None
    return str(value)


def _to_json(value):
    if value is None:
        return None
    return json.dumps(value)


def _extract_country(call):
    number = call.get('number')
    if isinstance(number, dict):
        return number.get('country')
    return None


class DbLoader:
    """
    Loads Aircall call data into a SQL Server staging table.
    Uses SQLAlchemy + pyodbc with ODBC Driver 17.
    """

    def __init__(self, sql_config, db_config, logger=None):
        self.logger = logger or setup_logger()
        self.sql_config = sql_config
        self.target_schema = db_config.get('target_schema', 'edw_stage')
        self.target_table = db_config.get('target_table', 'stage_aircall_list_all_calls')
        self.load_strategy = db_config.get('load_strategy', 'truncate_day')
        self.batch_size = db_config.get('batch_size', 1000)
        self.engine: Engine | None = None

    def __enter__(self):
        self._connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.engine:
            self.engine.dispose()
            self.logger.info("SQL Server connection closed.")

    def _connect(self):
        try:
            self.logger.info(f"Connecting to SQL Server: {self.sql_config['server']}...")
            connection_url = URL.create(
                "mssql+pyodbc",
                username=self.sql_config['username'],
                password=self.sql_config['password'],
                host=self.sql_config['server'],
                database=self.sql_config['database'],
                query={"driver": "ODBC Driver 17 for SQL Server"}
            )
            self.engine = create_engine(connection_url)

            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))

            self.logger.info("SQL Server connection verified.")
        except Exception as e:
            self.logger.error(f"Failed to connect to SQL Server: {e}")
            raise

    def transform_calls(self, calls):
        """
        Transform raw API call dicts into a DataFrame matching the DDL.

        Args:
            calls: List of call dicts from the Aircall API.

        Returns:
            pandas DataFrame with columns matching the target table.
        """
        self.logger.info(f"Transforming {len(calls)} calls to DataFrame...")
        rows = []
        for call in calls:
            row = {}
            for col_name, extractor in COLUMN_MAPPING.items():
                row[col_name] = extractor(call)
            rows.append(row)

        df = pd.DataFrame(rows)
        df = df.where(pd.notnull(df), None)
        self.logger.info(f"Transformation complete. DataFrame shape: {df.shape}")
        return df

    # Columns that use NVARCHAR(MAX) in the DDL (JSON object/array columns)
    _MAX_COLUMNS = {
        'user_json', 'contact_json', 'comments_json', 'number_json',
        'teams_json', 'tags_json', 'ivr_options_selected_json',
        'assigned_to_json', 'transferred_by_json', 'transferred_to_json',
    }

    # Columns with explicit non-string SQL types (matching API data types)
    _TYPED_COLUMNS = {
        'started_at': BigInteger(),    # API: integer (UNIX timestamp)
        'answered_at': BigInteger(),   # API: integer (UNIX timestamp)
        'ended_at': BigInteger(),      # API: integer (UNIX timestamp)
        'duration': Integer(),         # API: integer (seconds)
        'archived': Boolean(),         # API: boolean
        'cost': DECIMAL(15, 2),        # API: string (DEPRECATED), stored as decimal
    }

    def _get_column_dtypes(self, df):
        dtypes = {}
        for col_name in df.columns:
            if col_name == 'create_ts':
                continue  # let SQLAlchemy infer datetime
            elif col_name in self._TYPED_COLUMNS:
                dtypes[col_name] = self._TYPED_COLUMNS[col_name]
            elif col_name in self._MAX_COLUMNS:
                dtypes[col_name] = NVARCHAR(None)   # NVARCHAR(MAX)
            elif df[col_name].dtype == 'object':
                dtypes[col_name] = NVARCHAR(4000)   # NVARCHAR(4000)
        return dtypes

    def load(self, df, from_ts=None, to_ts=None):
        """
        Load DataFrame into the target staging table.

        Args:
            df: pandas DataFrame with transformed call data.
            from_ts: UNIX timestamp start of window (for truncate_day strategy).
            to_ts: UNIX timestamp end of window (for truncate_day strategy).
        """
        if df.empty:
            self.logger.warning("No data to load. Skipping.")
            return 0

        table_ref = f"[{self.target_schema}].[{self.target_table}]"
        sql_dtypes = self._get_column_dtypes(df)

        self.logger.info(
            f"Loading {len(df)} records into {table_ref} "
            f"(strategy={self.load_strategy})..."
        )

        with self.engine.begin() as conn:
            # Apply load strategy
            if self.load_strategy == 'truncate_all':
                self.logger.info(f"Truncating table: {table_ref}")
                conn.execute(text(f"TRUNCATE TABLE {table_ref}"))
                self.logger.info("Truncate complete.")

            elif self.load_strategy == 'truncate_day':
                if from_ts is not None and to_ts is not None:
                    self.logger.info(
                        f"Deleting existing records for window "
                        f"started_at between '{from_ts}' and '{to_ts}'..."
                    )
                    delete_sql = text(
                        f"DELETE FROM {table_ref} "
                        f"WHERE started_at >= :from_ts "
                        f"AND started_at <= :to_ts"
                    )
                    result = conn.execute(delete_sql, {'from_ts': from_ts, 'to_ts': to_ts})
                    self.logger.info(f"Deleted {result.rowcount} existing records.")
                else:
                    self.logger.warning(
                        "truncate_day strategy requires from_ts/to_ts. "
                        "Falling back to append."
                    )

            # Load data
            df.to_sql(
                name=self.target_table,
                con=conn,
                schema=self.target_schema,
                if_exists='append',
                index=False,
                dtype=sql_dtypes
            )

        self.logger.info(f"Successfully loaded {len(df)} records into {table_ref}.")
        return len(df)
