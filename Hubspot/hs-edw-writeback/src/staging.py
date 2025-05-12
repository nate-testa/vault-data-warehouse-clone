import src.timetracking as timetracking
import constants
import sqlite3
import json
import requests
import time
import logging
from collections import defaultdict

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)-8s %(name)-20s %(message)s",
)
logger = logging.getLogger(__name__)


def count_rows_in_sqlite_table(db_path, table_name):
    """Utility: return number of rows in given SQLite table."""
    conn = sqlite3.connect(db_path)
    try:
        cur = conn.execute(f"SELECT COUNT(*) FROM {table_name}")
        return cur.fetchone()[0]
    finally:
        conn.close()


class Staging:

    # @staticmethod
    def sync_to_staging_table(timestamp):
        """Main entry point: fetch all modified company goals and insert into SQLite."""
        logger.info("🚀 company goal staging started")
        fields = constants.company_goal_fields_to_query
        merged = defaultdict(dict)
        total_fetched = 0

        for field in fields:
            unix_ts = timetracking.format_unix_timestamp_for_hs_company_goals_query(timestamp)
            logger.debug(f"→ raw timestamp for HS query: {unix_ts!r}")

            query = Staging.build_company_goals_query(unix_ts, field)
            payload = json.dumps(query)
            logger.debug(f"→ POST payload for field '{field}': {payload}")

            batch = Staging.get_all_company_goals_modified_after_timestamp(query)
            logger.info(f"↪️  HS returned {len(batch)} records for '{field}'")
            total_fetched += len(batch)

            # merge into unified dict by object id
            for rec in batch:
                obj_id = rec.get("id")
                props = rec.get("properties", {})
                for k, v in props.items():
                    merged[obj_id][k] = v

            time.sleep(0.5)  # avoid rate limits

        logger.info(f"Total unique objects fetched: {len(merged)} (total raw fetched: {total_fetched})")

        inserted = 0
        for obj_id, props in merged.items():
            payload = Staging.build_staging_table_payload(props)
            if payload is None:
                continue
            if Staging.create_staging_table_record(payload):
                inserted += 1

        final_count = count_rows_in_sqlite_table(constants.company_goal_staging_table_path, "company_goal")
        logger.info(f"✅ staging complete: {inserted} new rows inserted, staging table now has {final_count} rows")

    @staticmethod
    def build_company_goals_query(unix_timestamp, field):
        """Construct the JSON body for a HubSpot search API call."""
        try:
            json_data = {
                "limit": 200,
                "properties": ["id", "broker_id", "hs_lastmodifieddate", field],
                "filterGroups": [
                    {
                        "filters": [
                            {
                                "propertyName": "write_back_company_goal",
                                "value": unix_timestamp,
                                "operator": "GT",
                            }
                        ]
                    }
                ],
            }
            logger.debug(f"Built HS query for '{field}': {json_data}")
            return json_data
        except Exception as e:
            logger.exception(f"Error building query for field '{field}': {e}")
            return {}

    @staticmethod
    def get_all_company_goals_modified_after_timestamp(query):
        """
        Calls HubSpot Search, handles pagination via `paging.next.after`,
        returns a flat list of result dicts.
        """
        url = f"{constants.hubapi}/crm/v3/objects/companies/search"
        all_results = []
        payload = query.copy()

        while True:
            data = json.dumps(payload)
            resp = requests.post(url, headers=constants.hs_headers, data=data)
            if not resp.ok:
                logger.error(f"HubSpot API error {resp.status_code}: {resp.text}")
                break

            body = resp.json()
            batch = body.get("results", [])
            all_results.extend(batch)

            # pagination token
            next_after = body.get("paging", {}).get("next", {}).get("after")
            if not next_after:
                break

            logger.debug(f"→ paging after={next_after}, fetching next batch")
            payload["after"] = next_after

        return all_results

    @staticmethod
    def build_staging_table_payload(props):
        """Map HubSpot fields into your staging‐table columns."""
        try:
            return {
                "agency_code": props["broker_id"],
                "last_activity_date": props["hs_lastmodifieddate"],
                "target_2024_gross_nb_premium_ytd": props.get("target_2024_gross_nb_premium_ytd"),
                "target_2024_policy_inforce_renewal_retention__": props.get("target_2024_policy_inforce_renewal_retention__"),
                "target_monthly_nb_quote_commitment__": props.get("target_monthly_nb_quote_commitment__"),
                "target_monthly_nb_policy_counts": props.get("target_monthly_nb_policy_counts"),
                "target_growth_2024_inforce_premium_over_last_year": props.get("target_growth_2024_inforce_premium_over_last_year"),
                "target_growth_2024_nb_premium_over_last_year": props.get("target_growth_2024_nb_premium_over_last_year"),
            }
        except Exception as e:
            logger.exception(f"Error building payload for broker_id={props.get('broker_id')}: {e}")
            return None

    @staticmethod
    def create_staging_table_record(payload):
        """Generate and execute the INSERT, logging success or failure."""
        sql = """
            INSERT INTO company_goal (
                agency_code, last_activity_date,
                target_2024_gross_nb_premium_ytd,
                target_2024_policy_inforce_renewal_retention__,
                target_monthly_nb_quote_commitment__,
                target_monthly_nb_policy_counts,
                target_growth_2024_inforce_premium_over_last_year,
                target_growth_2024_nb_premium_over_last_year
            ) VALUES (
                :agency_code, :last_activity_date,
                :target_2024_gross_nb_premium_ytd,
                :target_2024_policy_inforce_renewal_retention__,
                :target_monthly_nb_quote_commitment__,
                :target_monthly_nb_policy_counts,
                :target_growth_2024_inforce_premium_over_last_year,
                :target_growth_2024_nb_premium_over_last_year
            );
        """
        try:
            Staging.insert_record_into_staging_table(sql, payload)
            logger.debug(f"Inserted staging record: {payload}")
            return True
        except Exception:
            # insert_record_into_staging_table already logs exceptions
            return False

    @staticmethod
    def insert_record_into_staging_table(sql_query, params):
        """
        Executes a parametrized INSERT into SQLite, logs SQL and raises on failure.
        """
        logger.debug(f"Executing on staging DB: {sql_query}  params={params}")
        conn = sqlite3.connect(constants.company_goal_staging_table_path)
        try:
            conn.execute(sql_query, params)
            conn.commit()
        except Exception:
            logger.exception("Failed to insert into staging table")
            raise
        finally:
            conn.close()
