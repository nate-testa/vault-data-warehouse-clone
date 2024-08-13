import logging
import struct
import shutil
import urllib
import json
from datetime import datetime
import pandas as pd
import sqlalchemy as sa
from azure.identity import DefaultAzureCredential
from configparser import ConfigParser
from pathlib import Path
import pyodbc
import numpy as np
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_column_mapping(column_mapping_file):
    with open(column_mapping_file, 'r') as file:
        column_mapping = json.load(file)
    return column_mapping

class NFPDataProcessor:
    def __init__(self, file_path, column_mapping, validate_column_empty, column_to_validate):
        self.file_path = file_path
        self.column_mapping = column_mapping
        self.validate_column_empty = validate_column_empty
        self.column_to_validate = column_to_validate
        self.df = None

    def load_data(self):
        try:
            self.df = pd.read_csv(self.file_path)
            logging.info("CSV file loaded successfully.")
        except Exception as e:
            logging.error("Error loading CSV file: %s", e)
            raise

    def filter_empty_rows(self, column):
        before_count = len(self.df)
        self.df = self.df.dropna(subset=[column])
        after_count = len(self.df)
        logging.info(f"Filtered out {before_count - after_count} rows with empty values in column: {column}")

    def process_data(self):
        try:
            # Log original columns
            #logging.info(f"Original columns: {self.df.columns.tolist()}")

            # Rename columns
            self.df.rename(columns=self.column_mapping, inplace=True)
            #logging.info(f"Renamed columns: {self.df.columns.tolist()}")

            if self.validate_column_empty:
                if self.column_mapping[self.column_to_validate] not in self.df.columns:
                    logging.error(f"Validation column '{self.column_mapping[self.column_to_validate]}' not found in the dataframe columns: {self.df.columns.tolist()}")
                    raise ValueError(f"Validation column '{self.column_mapping[self.column_to_validate]}' not found in the dataframe.")
                self.filter_empty_rows(self.column_mapping[self.column_to_validate])

            self.df['create_ts'] = datetime.utcnow()
            self.df['update_ts'] = datetime.utcnow()
            self.df['product_type'] = 'Group Umbrella'
            self.df['product_nm'] = 'PEL'
            # Added Custom
            self.df['risk_group'] = self.df['insured_cert_no'] +"-"+ self.df["insured_first_name"] +"-"+ self.df["insured_last_name"]
            logging.info("Data processing completed successfully.")
        except Exception as e:
            logging.error("Error processing data: %s", e)
            raise

    def validate_and_convert_data(self, schema_info):
        try:
            # Ensure columns are correctly converted based on schema_info
            for _, row in schema_info.iterrows():
                col = row['COLUMN_NAME']
                dtype = row['DATA_TYPE']
                if col in self.df.columns:
                    self.df[col] = self.df[col].replace({pd.NaT: None, 'nan': None, 'NaN': None})
                    
                    if dtype in ['int', 'bigint', 'smallint', 'tinyint']:
                        self.df[col] = pd.to_numeric(self.df[col], errors='coerce').astype('Int64').fillna(0)
                    elif dtype in ['float', 'real', 'decimal', 'numeric']:
                        self.df[col] = pd.to_numeric(self.df[col], errors='coerce').apply(lambda x: round(x, 6) if pd.notnull(x) else 0.0)
                        #logging.info(f"Rounded column {col} to 6 decimal places.")
                    elif dtype == 'bit':
                        self.df[col] = self.df[col].astype('boolean')
                    elif dtype in ['varchar', 'nvarchar', 'text']:
                        self.df[col] = self.df[col].astype(str)
                    elif dtype in ['date', 'datetime', 'smalldatetime', 'datetime2']:
                        self.df[col] = pd.to_datetime(self.df[col], errors='coerce').dt.strftime('%Y-%m-%d %H:%M:%S.%f').str[:-3]
            logging.info("Data types converted successfully.")
        except Exception as e:
            logging.error("Error converting data types: %s", e)
            raise

    def get_data_frame(self):
        return self.df

class AzureSQLConnector:
    def __init__(self, server, database, auth_method, username=None, password=None, show_records='none'):
        self.server = server
        self.database = database
        self.auth_method = auth_method
        self.username = username
        self.password = password
        self.driver = "ODBC Driver 17 for SQL Server"
        self.connection_string = None
        self.engine = None
        self.show_records = show_records

    def create_connection_string(self):
        logging.info(f"Authentication method: {self.auth_method}")
        try:
            if self.auth_method == 'azure_function':
                credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
                token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
                token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
                conn_string = f"Driver={{{self.driver}}};Server={self.server};Database={self.database};Authentication=ActiveDirectoryAccessToken;TrustServerCertificate=yes;"
                self.connection_string = f"mssql+pyodbc:///?odbc_connect={urllib.parse.quote_plus(conn_string)}"
                self.engine = sa.create_engine(
                    self.connection_string,
                    connect_args={'attrs_before': {1256: token_struct}}
                )
                logging.info("Database connection string created successfully using Azure function.")
            elif self.auth_method == 'sql_server_credentials':
                if not self.username or not self.password:
                    raise ValueError("Username and password must be provided for SQL Server credentials.")
                conn_string = f"DRIVER={{{self.driver}}};SERVER={self.server};DATABASE={self.database};UID={self.username};PWD={self.password};TrustServerCertificate=yes;"
                self.connection_string = f"mssql+pyodbc:///?odbc_connect={urllib.parse.quote_plus(conn_string)}"
                self.engine = sa.create_engine(self.connection_string)
                logging.info("Database connection string created successfully using SQL Server credentials.")
            else:
                raise ValueError("Invalid authentication method specified.")
        except Exception as e:
            logging.error("Error creating database connection string: %s", e)
            raise

    def get_table_schema(self, table_name, schema):
        try:
            query = f"""
            SELECT COLUMN_NAME, DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = '{table_name}' AND TABLE_SCHEMA = '{schema}'
            """
            if self.auth_method == 'azure_function':
                schema_info = pd.read_sql(query, self.engine)
            elif self.auth_method == 'sql_server_credentials':
                connection_string = f"DRIVER={self.driver};SERVER={self.server};DATABASE={self.database};UID={self.username};PWD={self.password};TrustServerCertificate=yes;"
                connection = pyodbc.connect(connection_string)
                schema_info = pd.read_sql(query, connection)
                connection.close()
            return schema_info
        except Exception as e:
            logging.error("Error fetching table schema: %s", e)
            raise

    def insert_data_with_pyodbc(self, data_frame, table_name, schema, chunksize=5000):
        try:
            # Use pyodbc to insert data into SQL Server
            connection_string = f"DRIVER={self.driver};SERVER={self.server};DATABASE={self.database};UID={self.username};PWD={self.password};TrustServerCertificate=yes;"
            connection = pyodbc.connect(connection_string)
            cursor = connection.cursor()
    
            # Rename columns that require special handling
            data_frame = data_frame.rename(columns={
                'non_profit_d&o_liability_coverage': '[non_profit_d&o_liability_coverage]',
                'non_profit_d&o_liability_premium': '[non_profit_d&o_liability_premium]'
            })
    
            # Log the columns that will be used in the insert statement
            columns = data_frame.columns.tolist()
            logging.info(f"Columns to be used in insert statement: {columns}")            
    
            # Create the insert query template
            columns_str = ', '.join(columns)
            placeholders = ', '.join(['?' for _ in columns])
            insert_query_template = f"INSERT INTO {schema}.{table_name} ({columns_str}) VALUES ({placeholders})"
            logging.info(f"Insert query template: {insert_query_template}")
    
            # Convert DataFrame to list of tuples, handling NaN appropriately
            data_tuples = [
                tuple(None if (col in columns and pd.isna(value)) else None if pd.isna(value) else value 
                    for col, value in zip(columns, row)) 
                for row in data_frame.to_numpy()
            ]
    
            # Execute each query with the actual values
            for data_tuple in data_tuples:
                filled_query = insert_query_template
                for i, value in enumerate(data_tuple):
                    value_str = 'NULL' if value is None or value == 'None' else repr(value)
                    filled_query = filled_query.replace('?', value_str, 1)
                logging.info(f"Executing query: {filled_query}")
                cursor.execute(filled_query)
    
            connection.commit()
            cursor.close()
            connection.close()
        except Exception as e:
            logging.error(f"Error inserting data into the database with pyodbc: {e}")
            if self.show_records in ['all', 'error']:
                for i, row in enumerate(data_frame.iterrows()):
                    logging.error(f"Row {i}: {row}")
            raise

    def insert_data(self, data_frame, table_name, schema, chunksize=5000):
        try:
            schema_info = self.get_table_schema(table_name, schema)
            df_processor = NFPDataProcessor("", {}, False, "")  # Placeholder to use the method
            df_processor.df = data_frame
            df_processor.validate_and_convert_data(schema_info)
            if self.auth_method == 'sql_server_credentials':
                self.insert_data_with_pyodbc(df_processor.get_data_frame(), table_name, schema, chunksize)
            else:
                df_processor.get_data_frame().to_sql(table_name, con=self.engine, schema=schema, index=False, if_exists='append', chunksize=chunksize)
                logging.info("Data inserted into the database successfully using SQLAlchemy.")
        except Exception as e:
            logging.error("Error inserting data into the database: %s", e)
            if self.show_records in ['all', 'error']:
                for i, row in enumerate(data_frame.iterrows()):
                    logging.error(f"Row {i}: {row}")
            raise

def process_files(source_directory, processed_directory, log_directory, server, database, table_name, schema, chunksize, auth_method, username, password, column_mapping, validate_column_empty, column_to_validate, show_records):
    source_directory = Path(source_directory)
    processed_directory = Path(processed_directory)
    log_directory = Path(log_directory)

    # Ensure directories exist
    processed_directory.mkdir(parents=True, exist_ok=True)
    log_directory.mkdir(parents=True, exist_ok=True)

    # Create log file path
    log_file = log_directory / 'processed_files.log'

    # Get all files in the directory, ordered by filename
    files = sorted(source_directory.glob('*.csv'), key=lambda f: f.stat().st_mtime)

    for file_path in files:
        logging.info("Processing file: %s", file_path)

        nfp_processor = NFPDataProcessor(file_path, column_mapping, validate_column_empty, column_to_validate)

        try:
            nfp_processor.load_data()
            nfp_processor.process_data()
            df = nfp_processor.get_data_frame()
            logging.info("Data frame prepared for database insertion.")
        except Exception as e:
            logging.critical("Critical error in data preparation: %s", e)
            shutil.move(file_path, processed_directory / file_path.name)
            continue  # Skip to the next file

        azure_sql = AzureSQLConnector(server=server, database=database, auth_method=auth_method, username=username, password=password, show_records=show_records)

        try:
            azure_sql.create_connection_string()
            schema_info = azure_sql.get_table_schema(table_name, schema)
            nfp_processor.validate_and_convert_data(schema_info)
            df = nfp_processor.get_data_frame()
            azure_sql.insert_data(df, table_name=table_name, schema=schema, chunksize=chunksize)
            logging.info("NFP data imported successfully.")
        except Exception as e:
            logging.critical("Critical error in data insertion: %s", e)
            if show_records in ['all', 'error']:
                for i, row in enumerate(df.iterrows()):
                    logging.error(f"Row {i}: {row}")

        # Move the processed file to the Processed directory
        shutil.move(file_path, processed_directory / file_path.name)

        # Log the processed file
        with log_file.open('a') as log_f:
            log_f.write(f"{datetime.now()} - Processed file: {file_path.name}\n")

def main(server=None):
    # Load configuration
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(current_dir, 'config.ini')
    
    # Read the configuration file
    config = ConfigParser()
    config.read(config_path)
    
    source_directory = os.path.join(current_dir, config.get('DEFAULT', 'source_directory'))
    processed_directory = os.path.join(current_dir, config.get('DEFAULT', 'processed_directory'))
    log_directory = os.path.join(current_dir, config.get('DEFAULT', 'log_directory'))
    server = server if server is not None else config.get('DEFAULT', 'server')
    database = config.get('DEFAULT', 'database')
    table_name = config.get('DEFAULT', 'table_name')
    schema = config.get('DEFAULT', 'schema')
    chunksize = config.getint('DEFAULT', 'chunksize')
    auth_method = config.get('DEFAULT', 'auth_method')
    username = config.get('DEFAULT', 'username')
    password = config.get('DEFAULT', 'password')
    validate_column_empty = config.getboolean('DEFAULT', 'validate_column_empty')
    column_to_validate = config.get('DEFAULT', 'column_to_validate')
    column_mapping_file = os.path.join(current_dir, config.get('DEFAULT', 'column_mapping_file'))
    show_records = config.get('DEFAULT', 'show_records')

    column_mapping = load_column_mapping(column_mapping_file)

    logging.info(f"Loaded configuration - auth_method: {auth_method}")

    process_files(source_directory, processed_directory, log_directory, server, database, table_name, schema, chunksize, auth_method, username, password, column_mapping, validate_column_empty, column_to_validate, show_records)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Process files and insert data into Azure SQL.')
    parser.add_argument('--server', type=str, help='Azure SQL server')

    args = parser.parse_args()

    main(server=args.server)