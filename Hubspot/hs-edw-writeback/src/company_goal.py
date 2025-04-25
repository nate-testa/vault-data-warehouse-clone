import src.timetracking as timetracking
import constants
import pyodbc
import sqlite3
import logging

from src.logger import get_logger

logger = get_logger(__name__)


def count_rows_in_edw_table(conn, table_name):
    """Utility: return number of rows in given EDW table."""
    cur = conn.cursor()
    cur.execute(f"SELECT COUNT(*) FROM {table_name}")
    return cur.fetchone()[0]


class CompanyGoal:

    @staticmethod
    def load_to_edw(timestamp):
        """
        1) Read all new company goals from staging.
        2) Insert each into EDW.
        3) Log a summary.
        """
        logger.info("🚀 company goal sync to EDW started")
        data = CompanyGoal.get_data_from_staging_table(timestamp)
        total = len(data)
        loaded = 0
        failed = 0

        for record in data:
            try:
                CompanyGoal.create_edw_table_record(record)
                loaded += 1
                logger.debug(f"Loaded to EDW: {record}")
            except Exception:
                failed += 1
                # create_edw_table_record logs the exception

        logger.info(
            f"✅ EDW load complete: {loaded}/{total} succeeded, {failed} failed."
        )

        # Optional: final EDW row count for sanity
        try:
            conn = pyodbc.connect(constants.connection_string)
            count = count_rows_in_edw_table(conn, "edw_stage.hubspot_company_goals")
            logger.info(f"EDW table now contains {count} total rows.")
            conn.close()
        except Exception:
            logger.exception("Unable to fetch final EDW row count")

    @staticmethod
    def get_data_from_staging_table(timestamp):
        """
        Pull all rows from SQLite staging whose last_activity_date >= timestamp.
        Returns list of tuples.
        """
        formatted_ts = timetracking.format_timestamp_for_staging_query(timestamp)
        sql = """
            SELECT
                agency_code,
                last_activity_date,
                target_2024_gross_nb_premium_ytd,
                target_2024_policy_inforce_renewal_retention__,
                target_monthly_nb_quote_commitment__,
                target_monthly_nb_policy_counts,
                target_growth_2024_inforce_premium_over_last_year,
                target_growth_2024_nb_premium_over_last_year
            FROM company_goal
            WHERE last_activity_date >= ?
        """
        try:
            conn = sqlite3.connect(constants.company_goal_staging_table_path)
            cur = conn.cursor()
            cur.execute(sql, (formatted_ts,))
            rows = cur.fetchall()
            conn.close()

            if rows:
                logger.info(f"↪️ Retrieved {len(rows)} rows from staging (since {formatted_ts})")
            else:
                logger.info("↪️ No new entries in staging table")
            return rows

        except Exception:
            logger.exception("Error querying staging table")
            return []

    @staticmethod
    def create_edw_table_record(record):
        """
        Inserts one staging record tuple into the EDW table using parameterized SQL.
        """
        sql = """
            INSERT INTO edw_stage.hubspot_company_goals (
                agency_code, last_activity_date,
                target_2024_gross_nb_premium_ytd,
                target_2024_policy_inforce_renewal_retention__,
                target_monthly_nb_quote_commitment__,
                target_monthly_nb_policy_counts,
                target_growth_2024_inforce_premium_over_last_year,
                target_growth_2024_nb_premium_over_last_year
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        try:
            CompanyGoal.insert_data_into_edw_table(sql, record)
        except Exception:
            logger.exception(f"Failed to insert into EDW: {record}")
            raise

    @staticmethod
    def insert_data_into_edw_table(sql_query, params):
        """
        Execute parameterized INSERT into EDW via ODBC.
        """
        logger.debug(f"Executing EDW INSERT: {sql_query} | params={params}")
        conn = pyodbc.connect(constants.connection_string)
        try:
            cur = conn.cursor()
            cur.execute(sql_query, params)
            conn.commit()
        except Exception:
            logger.exception("Error writing to EDW")
            raise
        finally:
            conn.close()
