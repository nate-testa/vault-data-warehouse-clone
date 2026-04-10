"""
Pre-sync module: pulls HubSpot-native contacts into SQL Server mapping tables
before each integration run, preventing duplicate creation.
"""

import json
import time
import requests

import constants
from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA
from shared.logger import get_logger

logger = get_logger(__name__)

S = ID_MAP_SCHEMA

HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {constants.hs_token}'
}


def _search_contacts(filter_groups, properties):
    """Search HubSpot contacts with pagination."""
    all_results = []
    after = None

    while True:
        body = {
            'filterGroups': filter_groups,
            'properties': properties,
            'limit': 100
        }
        if after:
            body['after'] = after

        try:
            res = requests.post(
                'https://api.hubapi.com/crm/v3/objects/contacts/search',
                headers=HEADERS,
                json=body,
                timeout=120
            )
            if res.status_code != 200:
                logger.error(f"Pre-sync HubSpot search failed: {res.status_code} - {res.text}")
                break

            data = res.json()
            all_results.extend(data.get('results', []))

            paging = data.get('paging', {}).get('next', {})
            after = paging.get('after')
            if not after:
                break

            time.sleep(0.25)
        except Exception as exc:
            logger.error(f"Pre-sync HubSpot search error: {exc}")
            break

    return all_results


def _get_existing_ids(conn, table, id_column):
    """Get set of business keys already in the mapping table."""
    cursor = conn.cursor()
    cursor.execute(f"SELECT {id_column} FROM {S}.{table}")
    return {str(row[0]) for row in cursor.fetchall()}


def _sync_producers(conn):
    """Pull producers from HubSpot that are missing from the mapping table."""
    contacts = _search_contacts(
        [{'filters': [{'propertyName': 'producer_id', 'operator': 'HAS_PROPERTY'}]}],
        ['producer_id', 'broker_id', 'email']
    )

    existing = _get_existing_ids(conn, 'producer', 'producer_id')
    inserted = 0

    # Deduplicate by producer_id - keep the one with email
    by_pid = {}
    for c in contacts:
        pid = c['properties'].get('producer_id')
        if pid and pid not in existing:
            if pid not in by_pid or (c['properties'].get('email') and not by_pid[pid]['properties'].get('email')):
                by_pid[pid] = c

    for pid, c in by_pid.items():
        props = c['properties']
        try:
            cursor = conn.cursor()
            cursor.execute(
                f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                (c['id'], pid, props.get('broker_id', ''), props.get('email', ''))
            )
            conn.commit()
            inserted += 1
        except Exception as e:
            logger.error(f"Pre-sync: failed to insert producer {pid}: {e}")

    return inserted


def _sync_customers(conn):
    """Pull customers from HubSpot that are missing from the mapping table."""
    contacts = _search_contacts(
        [{'filters': [{'propertyName': 'customer_id', 'operator': 'HAS_PROPERTY'}]}],
        ['customer_id', 'broker_id', 'email']
    )

    existing = _get_existing_ids(conn, 'customer', 'customer_id')
    inserted = 0

    by_cid = {}
    for c in contacts:
        cid = c['properties'].get('customer_id')
        if cid and cid not in existing:
            if cid not in by_cid or (c['properties'].get('email') and not by_cid[cid]['properties'].get('email')):
                by_cid[cid] = c

    for cid, c in by_cid.items():
        props = c['properties']
        try:
            cursor = conn.cursor()
            cursor.execute(
                f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                (c['id'], cid, props.get('broker_id', ''), props.get('email', ''))
            )
            conn.commit()
            inserted += 1
        except Exception as e:
            logger.error(f"Pre-sync: failed to insert customer {cid}: {e}")

    return inserted


def hubspot_presync():
    """Pull HubSpot-native contacts into mapping tables before sync."""
    logger.info("Running pre-sync: checking for HubSpot contacts not in mapping tables...")
    conn = get_id_map_connection()

    try:
        p_count = _sync_producers(conn)
        c_count = _sync_customers(conn)

        if p_count > 0 or c_count > 0:
            logger.info(f"Pre-sync complete: {p_count} producers and {c_count} customers added to mapping tables")
        else:
            logger.info("Pre-sync complete: all HubSpot contacts already mapped")
    except Exception as e:
        logger.error(f"Pre-sync error: {e}")
    finally:
        conn.close()
