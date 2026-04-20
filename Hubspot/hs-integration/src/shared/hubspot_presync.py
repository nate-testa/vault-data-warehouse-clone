"""
Pre-sync module: pulls HubSpot-native contacts into SQL Server mapping tables
before each integration run, preventing duplicate creation.
"""

import json
import time
import requests

import constants
from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA, STAGING_SCHEMA
from shared.logger import get_logger

logger = get_logger(__name__)

S = ID_MAP_SCHEMA
STG = STAGING_SCHEMA

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


def _sync_staging_email_matches(conn):
    """Pull ALL HubSpot contacts into staging, join on email to EDW feeds,
    and auto-insert matches into mapping tables.
    This catches website-created contacts (CRM_UI, FORM) that have no
    producer_id/customer_id but whose email matches an EDW record.
    """
    # Pull all contacts from HubSpot
    contacts = _search_contacts(
        [{'filters': [{'propertyName': 'hs_object_id', 'operator': 'HAS_PROPERTY'}]}],
        ['firstname', 'lastname', 'email', 'type', 'producer_id', 'customer_id',
         'broker_id', 'hs_object_source', 'createdate']
    )
    if not contacts:
        logger.info("Pre-sync staging: no contacts found in HubSpot")
        return 0, 0

    logger.info(f"Pre-sync staging: pulled {len(contacts)} contacts from HubSpot")

    cursor = conn.cursor()

    # Full refresh: clear and repopulate
    cursor.execute(f"DELETE FROM {STG}.hubspot_contact")
    conn.commit()

    for c in contacts:
        props = c['properties']
        cursor.execute(f"""
            INSERT INTO {STG}.hubspot_contact
            (hs_contact_id, email, firstname, lastname, type, producer_id, customer_id,
             broker_id, hs_object_source, hs_createdate, match_status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'UNPROCESSED')
        """, (
            c['id'],
            props.get('email', ''),
            props.get('firstname', ''),
            props.get('lastname', ''),
            props.get('type', ''),
            props.get('producer_id', ''),
            props.get('customer_id', ''),
            props.get('broker_id', ''),
            props.get('hs_object_source', ''),
            props.get('createdate', '')
        ))
    conn.commit()

    # Email join: match staging contacts (without business keys) to EDW feeds
    # Producer matches
    cursor.execute(f"""
        SELECT s.hs_contact_id, s.email, f.producer_id, f.broker_id
        FROM {STG}.hubspot_contact s
        INNER JOIN edw_integration.producer_hubspot_feed f
            ON LOWER(LTRIM(RTRIM(s.email))) = LOWER(LTRIM(RTRIM(f.email)))
        WHERE s.email IS NOT NULL AND s.email <> ''
          AND (s.producer_id IS NULL OR s.producer_id = '')
          AND NOT EXISTS (
              SELECT 1 FROM {S}.producer p WHERE p.producer_id = f.producer_id
          )
    """)
    p_matches = cursor.fetchall()

    p_inserted = 0
    for hs_id, email, pid, bid in p_matches:
        try:
            cursor.execute(f"""
                INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, email, created, updated)
                VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())
            """, (hs_id, pid, bid, email))
            cursor.execute(f"""
                UPDATE {STG}.hubspot_contact
                SET matched_edw_producer_id = %s, match_status = 'AUTO_MATCHED',
                    match_source = 'email_join_producer', updated = GETDATE()
                WHERE hs_contact_id = %s
            """, (pid, hs_id))
            conn.commit()
            p_inserted += 1
            logger.info(f"Pre-sync staging: auto-matched producer email={email} -> producer_id={pid}")
        except Exception as e:
            logger.error(f"Pre-sync staging: failed to insert producer match {pid}: {e}")

    # Customer matches
    cursor.execute(f"""
        SELECT s.hs_contact_id, s.email, f.customer_id, f.broker_id
        FROM {STG}.hubspot_contact s
        INNER JOIN edw_integration.customer_hubspot_feed f
            ON LOWER(LTRIM(RTRIM(s.email))) = LOWER(LTRIM(RTRIM(f.email)))
        WHERE s.email IS NOT NULL AND s.email <> ''
          AND (s.customer_id IS NULL OR s.customer_id = '')
          AND NOT EXISTS (
              SELECT 1 FROM {S}.customer c WHERE c.customer_id = f.customer_id
          )
    """)
    c_matches = cursor.fetchall()

    c_inserted = 0
    for hs_id, email, cid, bid in c_matches:
        try:
            cursor.execute(f"""
                INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, email, created, updated)
                VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())
            """, (hs_id, cid, bid, email))
            cursor.execute(f"""
                UPDATE {STG}.hubspot_contact
                SET matched_edw_customer_id = %s, match_status = 'AUTO_MATCHED',
                    match_source = 'email_join_customer', updated = GETDATE()
                WHERE hs_contact_id = %s
            """, (cid, hs_id))
            conn.commit()
            c_inserted += 1
            logger.info(f"Pre-sync staging: auto-matched customer email={email} -> customer_id={cid}")
        except Exception as e:
            logger.error(f"Pre-sync staging: failed to insert customer match {cid}: {e}")

    # Mark remaining rows
    cursor.execute(f"""
        UPDATE {STG}.hubspot_contact
        SET match_status = 'NO_MATCH', updated = GETDATE()
        WHERE match_status = 'UNPROCESSED'
          AND (producer_id IS NULL OR producer_id = '')
          AND (customer_id IS NULL OR customer_id = '')
    """)
    cursor.execute(f"""
        UPDATE {STG}.hubspot_contact
        SET match_status = 'ALREADY_MAPPED', updated = GETDATE()
        WHERE match_status = 'UNPROCESSED'
    """)
    conn.commit()

    return p_inserted, c_inserted


def hubspot_presync():
    """Pull HubSpot-native contacts into mapping tables before sync."""
    logger.info("Running pre-sync: checking for HubSpot contacts not in mapping tables...")
    conn = get_id_map_connection()

    try:
        # Phase 1: Sync contacts that already have producer_id/customer_id set
        p_count = _sync_producers(conn)
        c_count = _sync_customers(conn)

        if p_count > 0 or c_count > 0:
            logger.info(f"Pre-sync phase 1: {p_count} producers and {c_count} customers added (by business key)")

        # Phase 2: Staging table email join for contacts WITHOUT business keys
        p_staged, c_staged = _sync_staging_email_matches(conn)

        if p_staged > 0 or c_staged > 0:
            logger.info(f"Pre-sync phase 2: {p_staged} producers and {c_staged} customers added (by email match)")

        total = p_count + c_count + p_staged + c_staged
        if total == 0:
            logger.info("Pre-sync complete: all HubSpot contacts already mapped")
        else:
            logger.info(f"Pre-sync complete: {total} total mappings added")
    except Exception as e:
        logger.error(f"Pre-sync error: {e}")
    finally:
        conn.close()
