"""
Standalone script to sync HubSpot contacts into the SQL Server mapping tables.

Purpose:
  1. Pulls ALL HubSpot contacts that have a producer_id or customer_id set
  2. Inserts any that are missing from edw_hubspot.producer / edw_hubspot.customer
  3. Detects and remediates duplicate contacts (email-less INTEGRATION dupes)

Usage:
  cd /home/vuhubspotadmin/hs-integration
  source venv/bin/activate
  python3 sync_hubspot_contacts.py [--dry-run]

  --dry-run   Show what would be done without making changes
"""

import sys
import os
import json
import time
import argparse
import requests
import logging
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import constants
from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA
from shared.logger import get_logger

logger = get_logger('sync_hubspot_contacts')

# Add a dedicated log file for the standalone script
_log_dir = constants.log_folder_path
os.makedirs(_log_dir, exist_ok=True)
_log_file = os.path.join(_log_dir, f'sync_hubspot_contacts_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')
_fh = logging.FileHandler(_log_file)
_fh.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(name)s - %(message)s', datefmt='%b %d %H:%M:%S'))
_fh.setLevel(logging.DEBUG)
logger.addHandler(_fh)

S = ID_MAP_SCHEMA

HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {constants.hs_token}'
}

CONTACT_PROPERTIES = [
    'firstname', 'lastname', 'email', 'type',
    'producer_id', 'customer_id', 'broker_id',
    'hs_object_source', 'hs_object_source_detail_1'
]


def search_hubspot_contacts(filter_groups, properties=None):
    """Search HubSpot contacts with pagination. Returns list of all matching contacts."""
    if properties is None:
        properties = CONTACT_PROPERTIES

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

        res = requests.post(
            'https://api.hubapi.com/crm/v3/objects/contacts/search',
            headers=HEADERS,
            json=body,
            timeout=120
        )

        if res.status_code != 200:
            logger.error(f"HubSpot search failed: {res.status_code} - {res.text}")
            break

        data = res.json()
        all_results.extend(data.get('results', []))

        paging = data.get('paging', {}).get('next', {})
        after = paging.get('after')
        if not after:
            break

        time.sleep(0.25)  # rate limit: 5 req/sec

    return all_results


def get_existing_mapping_ids(conn, table, id_column):
    """Get all existing business key -> (hs_contact_id, email) mappings from SQL Server."""
    cursor = conn.cursor()
    cursor.execute(f"SELECT {id_column}, hs_contact_id, email FROM {S}.{table}")
    rows = cursor.fetchall()
    return {str(row[0]): {'hs_id': str(row[1]), 'email': row[2]} for row in rows}


def delete_hubspot_contact(contact_id):
    """Delete a contact from HubSpot by ID."""
    res = requests.delete(
        f'https://api.hubapi.com/crm/v3/objects/contacts/{contact_id}',
        headers=HEADERS,
        timeout=120
    )
    return res.status_code == 204


def pull_producers(conn, dry_run=False):
    """Pull all HubSpot contacts with producer_id into mapping table."""
    logger.info("=== SYNCING PRODUCERS ===")
    print("\n=== SYNCING PRODUCERS ===")

    # Get all contacts with producer_id set
    contacts = search_hubspot_contacts([{
        'filters': [{'propertyName': 'producer_id', 'operator': 'HAS_PROPERTY'}]
    }])
    logger.info(f"HubSpot contacts with producer_id: {len(contacts)}")
    print(f"  HubSpot contacts with producer_id: {len(contacts)}")

    # Get existing mappings
    existing = get_existing_mapping_ids(conn, 'producer', 'producer_id')
    logger.info(f"Already in producer mapping table: {len(existing)}")
    print(f"  Already in mapping table: {len(existing)}")

    # Group contacts by producer_id to detect duplicates
    by_producer_id = {}
    for c in contacts:
        pid = c['properties'].get('producer_id')
        if pid:
            by_producer_id.setdefault(pid, []).append(c)

    inserted = 0
    dupes_fixed = 0
    emails_backfilled = 0
    skipped = 0

    for pid, group in by_producer_id.items():
        if len(group) > 1:
            # DUPLICATE DETECTED - pick the one with email, delete the one without
            with_email = [c for c in group if c['properties'].get('email')]
            without_email = [c for c in group if not c['properties'].get('email')]

            if with_email and without_email:
                keep = with_email[0]
                keep_id = keep['id']
                keep_props = keep['properties']

                for dupe in without_email:
                    dupe_id = dupe['id']
                    logger.warning(f"DUPLICATE producer_id={pid}: KEEP {keep_id} ({keep_props.get('email')}), DELETE {dupe_id} (no email)")
                    print(f"  DUPLICATE: producer_id={pid}")
                    print(f"    KEEP:   {keep_id} ({keep_props.get('firstname')} {keep_props.get('lastname')}, email={keep_props.get('email')}, source={keep_props.get('hs_object_source')})")
                    print(f"    DELETE: {dupe_id} (no email, source={dupe['properties'].get('hs_object_source')})")

                    if not dry_run:
                        if delete_hubspot_contact(dupe_id):
                            logger.info(f"Deleted duplicate contact {dupe_id} for producer_id={pid}")
                            print(f"    -> Deleted {dupe_id} from HubSpot")
                        else:
                            logger.error(f"Failed to delete duplicate contact {dupe_id}")
                            print(f"    -> FAILED to delete {dupe_id}")

                    dupes_fixed += 1

                # Update or insert mapping to point to the correct (kept) contact
                broker_id = keep_props.get('broker_id', '')
                email = keep_props.get('email', '')

                if pid in existing:
                    if existing[pid]['hs_id'] != keep_id:
                        if not dry_run:
                            cursor = conn.cursor()
                            cursor.execute(
                                f"UPDATE {S}.producer SET hs_contact_id = %s, email = %s, updated = GETDATE() WHERE producer_id = %s",
                                (keep_id, email, pid)
                            )
                            conn.commit()
                        print(f"    -> Updated mapping: {existing[pid]['hs_id']} -> {keep_id}")
                    skipped += 1
                else:
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                            (keep_id, pid, broker_id, email)
                        )
                        conn.commit()
                    inserted += 1
                    print(f"    -> Inserted mapping for {keep_id}")
            else:
                # All have email or all lack email - just pick the first
                keep = group[0]
                if pid not in existing:
                    props = keep['properties']
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                            (keep['id'], pid, props.get('broker_id', ''), props.get('email', ''))
                        )
                        conn.commit()
                    inserted += 1
                else:
                    skipped += 1
        else:
            # Single contact for this producer_id
            c = group[0]
            hs_email = c['properties'].get('email', '')
            if pid not in existing:
                props = c['properties']
                if not dry_run:
                    cursor = conn.cursor()
                    cursor.execute(
                        f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                        (c['id'], pid, props.get('broker_id', ''), hs_email)
                    )
                    conn.commit()
                inserted += 1
            else:
                # Already mapped - backfill email if missing in SQL Server but present in HubSpot
                if hs_email and not existing[pid]['email']:
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"UPDATE {S}.producer SET email = %s, updated = GETDATE() WHERE producer_id = %s",
                            (hs_email, pid)
                        )
                        conn.commit()
                    emails_backfilled += 1
                skipped += 1

    logger.info(f"Producer results: {inserted} inserted, {dupes_fixed} duplicates fixed, {emails_backfilled} emails backfilled, {skipped} already mapped")
    print(f"\n  Results: {inserted} inserted, {dupes_fixed} duplicates fixed, {emails_backfilled} emails backfilled, {skipped} already mapped")
    return inserted, dupes_fixed, emails_backfilled


def pull_customers(conn, dry_run=False):
    """Pull all HubSpot contacts with customer_id into mapping table."""
    logger.info("=== SYNCING CUSTOMERS ===")
    print("\n=== SYNCING CUSTOMERS ===")

    contacts = search_hubspot_contacts([{
        'filters': [{'propertyName': 'customer_id', 'operator': 'HAS_PROPERTY'}]
    }])
    logger.info(f"HubSpot contacts with customer_id: {len(contacts)}")
    print(f"  HubSpot contacts with customer_id: {len(contacts)}")

    existing = get_existing_mapping_ids(conn, 'customer', 'customer_id')
    logger.info(f"Already in customer mapping table: {len(existing)}")
    print(f"  Already in mapping table: {len(existing)}")

    by_customer_id = {}
    for c in contacts:
        cid = c['properties'].get('customer_id')
        if cid:
            by_customer_id.setdefault(cid, []).append(c)

    inserted = 0
    dupes_fixed = 0
    emails_backfilled = 0
    skipped = 0

    for cid, group in by_customer_id.items():
        if len(group) > 1:
            with_email = [c for c in group if c['properties'].get('email')]
            without_email = [c for c in group if not c['properties'].get('email')]

            if with_email and without_email:
                keep = with_email[0]
                keep_id = keep['id']
                keep_props = keep['properties']

                for dupe in without_email:
                    dupe_id = dupe['id']
                    print(f"  DUPLICATE: customer_id={cid}")
                    print(f"    KEEP:   {keep_id} ({keep_props.get('firstname')} {keep_props.get('lastname')}, email={keep_props.get('email')})")
                    print(f"    DELETE: {dupe_id} (no email)")

                    if not dry_run:
                        if delete_hubspot_contact(dupe_id):
                            logger.info(f"Deleted duplicate contact {dupe_id} for customer_id={cid}")
                            print(f"    -> Deleted {dupe_id} from HubSpot")
                        else:
                            logger.error(f"Failed to delete duplicate contact {dupe_id}")
                            print(f"    -> FAILED to delete {dupe_id}")
                    dupes_fixed += 1

                broker_id = keep_props.get('broker_id', '')
                email = keep_props.get('email', '')

                if cid in existing:
                    if existing[cid]['hs_id'] != keep_id:
                        if not dry_run:
                            cursor = conn.cursor()
                            cursor.execute(
                                f"UPDATE {S}.customer SET hs_contact_id = %s, email = %s, updated = GETDATE() WHERE customer_id = %s",
                                (keep_id, email, cid)
                            )
                            conn.commit()
                        print(f"    -> Updated mapping: {existing[cid]['hs_id']} -> {keep_id}")
                    skipped += 1
                else:
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                            (keep_id, cid, broker_id, email)
                        )
                        conn.commit()
                    inserted += 1
            else:
                keep = group[0]
                if cid not in existing:
                    props = keep['properties']
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                            (keep['id'], cid, props.get('broker_id', ''), props.get('email', ''))
                        )
                        conn.commit()
                    inserted += 1
                else:
                    skipped += 1
        else:
            c = group[0]
            hs_email = c['properties'].get('email', '')
            if cid not in existing:
                props = c['properties']
                if not dry_run:
                    cursor = conn.cursor()
                    cursor.execute(
                        f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, email, created, updated) VALUES (%s, %s, %s, %s, GETDATE(), GETDATE())",
                        (c['id'], cid, props.get('broker_id', ''), hs_email)
                    )
                    conn.commit()
                inserted += 1
            else:
                # Already mapped - backfill email if missing in SQL Server but present in HubSpot
                if hs_email and not existing[cid]['email']:
                    if not dry_run:
                        cursor = conn.cursor()
                        cursor.execute(
                            f"UPDATE {S}.customer SET email = %s, updated = GETDATE() WHERE customer_id = %s",
                            (hs_email, cid)
                        )
                        conn.commit()
                    emails_backfilled += 1
                skipped += 1

    logger.info(f"Customer results: {inserted} inserted, {dupes_fixed} duplicates fixed, {emails_backfilled} emails backfilled, {skipped} already mapped")
    print(f"\n  Results: {inserted} inserted, {dupes_fixed} duplicates fixed, {emails_backfilled} emails backfilled, {skipped} already mapped")
    return inserted, dupes_fixed, emails_backfilled


def run_presync(dry_run=False):
    """Run the pre-sync to pull HubSpot contacts into mapping tables.
    
    This is also called from main.py before each sync execution.
    """
    logger.info("Starting HubSpot contact pre-sync")
    conn = get_id_map_connection()

    try:
        p_ins, p_dupes, p_emails = pull_producers(conn, dry_run)
        c_ins, c_dupes, c_emails = pull_customers(conn, dry_run)

        total_inserted = p_ins + c_ins
        total_dupes = p_dupes + c_dupes
        total_emails = p_emails + c_emails

        if total_inserted > 0 or total_dupes > 0 or total_emails > 0:
            logger.info(f"Pre-sync complete: {total_inserted} mappings inserted, {total_dupes} duplicates fixed, {total_emails} emails backfilled")
        else:
            logger.info("Pre-sync complete: no changes needed")

        return total_inserted, total_dupes, total_emails
    finally:
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Sync HubSpot contacts into SQL Server mapping tables')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without making changes')
    args = parser.parse_args()

    logger.info(f"Log file: {_log_file}")
    print(f"Log file: {_log_file}\n")

    if args.dry_run:
        print("*** DRY RUN MODE - no changes will be made ***\n")
        logger.info("DRY RUN MODE")

    inserted, dupes, emails = run_presync(dry_run=args.dry_run)

    summary = f"SUMMARY: {inserted} mappings inserted, {dupes} duplicates fixed, {emails} emails backfilled"
    if args.dry_run:
        summary += " (dry run - no actual changes were made)"

    print(f"\n{'=' * 60}")
    print(summary)
    print(f"{'=' * 60}")
    logger.info(summary)
