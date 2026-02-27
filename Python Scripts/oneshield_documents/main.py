import sys
import json
import logging
import os
import argparse
from datetime import datetime
from config_manager import ConfigManager
from api_client import APIClient
from blob_storage import BlobStorageManager

# Ensure logs directory exists
logs_dir = os.path.join(os.path.dirname(__file__), 'logs')
os.makedirs(logs_dir, exist_ok=True)

# Generate log filename with timestamp
log_filename = os.path.join(logs_dir, f'os_document_extract_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

# Setup logging to both file and console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("OSDocumentExtract")


def parse_args():
    parser = argparse.ArgumentParser(
        description="OS Document Extract",
        epilog="""
Examples:
  Run all requests (config payloads + input files):
    python3 main.py

  Run a specific request from config:
    python3 main.py -r clm001_claims

  Override with CLI params (skips config payload / input_file):
    python3 main.py -r clm002_customers -p customerName="John Doe"
    python3 main.py -r clm001_claims -p documentSubTypes="Estimate of Damages,BI/UM Demand" -p documentType=Claim

  Multiple customers (one API call each):
    python3 main.py -r clm002_customers -p customerName="John Doe" -p customerName="Jane Smith"
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--request', '-r',
        help='Run a specific request by name (from config.yml). Omit to run all.',
        default=None
    )
    parser.add_argument(
        '--param', '-p',
        action='append',
        metavar='KEY=VALUE',
        help='Override payload parameter (repeatable). Comma-separated values become a list. '
             'When provided, config payload and input_file are ignored.'
    )
    return parser.parse_args()


def parse_params(param_list):
    """Parse --param KEY=VALUE arguments into a list of payload dicts.

    - Comma-separated values become a list (sent as-is in one payload).
      E.g. --param documentSubTypes="Estimate of Damages,BI/UM Demand"
           -> {"documentSubTypes": ["Estimate of Damages", "BI/UM Demand"]}

    - Repeating the same key creates separate payloads (one request per value).
      E.g. --param customerName="A" --param customerName="B"
           -> [{"customerName": "A"}, {"customerName": "B"}]

    Returns a list of payload dicts.
    """
    from collections import OrderedDict

    raw = OrderedDict()  # key -> list of parsed values
    for item in param_list:
        if '=' not in item:
            raise ValueError(f"Invalid --param format '{item}'. Expected KEY=VALUE")
        key, value = item.split('=', 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")

        # Comma-separated values become a list (for array fields like documentSubTypes)
        if ',' in value:
            parsed_value = [v.strip() for v in value.split(',')]
        else:
            parsed_value = value

        raw.setdefault(key, []).append(parsed_value)

    # Find key(s) with multiple values -> generate separate payloads
    iterate_key = None
    for key, values in raw.items():
        if len(values) > 1:
            if iterate_key:
                raise ValueError("Only one key can be repeated via --param. "
                                 f"Found duplicates for '{iterate_key}' and '{key}'.")
            iterate_key = key

    if iterate_key:
        # Build one payload per value of the repeated key
        base = {k: vs[0] for k, vs in raw.items() if k != iterate_key}
        payloads = []
        for val in raw[iterate_key]:
            payload = dict(base)
            payload[iterate_key] = val
            payloads.append(payload)
        return payloads
    else:
        # Single payload
        return [{k: vs[0] for k, vs in raw.items()}]


def load_input_file(filepath):
    """Load a JSON input file (e.g. customers.json) relative to the script directory."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    full_path = os.path.join(script_dir, filepath)

    if not os.path.exists(full_path):
        raise FileNotFoundError(f"Input file not found: {full_path}")

    with open(full_path, 'r') as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError(f"Input file must contain a JSON array: {filepath}")

    return data


if __name__ == "__main__":
    args = parse_args()

    logger.info("=" * 60)
    logger.info("Starting OS Document Extract Process")
    logger.info(f"Log file: {log_filename}")
    logger.info("=" * 60)

    try:
        # 1. Init Config (loads secrets from Key Vault or static)
        config = ConfigManager(logger)

        # 2. Init API Client & Blob Storage Manager
        client = APIClient(config, logger)
        blob_mgr = BlobStorageManager(config, logger)

        # 3. Authenticate
        client.authenticate()

        # 4. Determine which requests to run
        all_requests = config.config.get('requests', {})
        if not all_requests:
            raise ValueError("No requests defined in config.yml")

        if args.request:
            if args.request not in all_requests:
                raise ValueError(f"Request '{args.request}' not found. "
                                 f"Available: {list(all_requests.keys())}")
            requests_to_run = {args.request: all_requests[args.request]}
        else:
            requests_to_run = all_requests

        logger.info(f"Requests to process: {list(requests_to_run.keys())}")

        # Check for CLI param overrides
        cli_payloads = None
        if args.param:
            cli_payloads = parse_params(args.param)
            logger.info(f"CLI --param override: {cli_payloads}")
            if not args.request:
                raise ValueError("--param requires --request/-r to specify which request to run")

        # 5. Process each request
        all_results = {}
        for req_name, req_config in requests_to_run.items():
            endpoint = req_config.get('endpoint')
            input_file = req_config.get('input_file')

            if cli_payloads:
                # CLI override mode: use --param payloads (ignore config payload & input_file)
                for idx, payload in enumerate(cli_payloads, 1):
                    if len(cli_payloads) == 1:
                        label = req_name
                    else:
                        # Build a readable label from the payload values
                        short = "_".join(str(v).replace(' ', '_')[:30]
                                         for v in payload.values() if isinstance(v, str))
                        label = f"{req_name}_{idx}_{short}" if short else f"{req_name}_{idx}"

                    logger.info(f"Using CLI payload for {label}: {payload}")
                    results = client.process_request(label, endpoint, payload)
                    all_results[label] = results

            elif input_file:
                # Batch mode: load list from JSON file and run one request per item
                items = load_input_file(input_file)
                logger.info(f"Loaded {len(items)} items from {input_file}")

                for idx, item in enumerate(items, 1):
                    # Build payload: item can be a string (customerName) or a dict
                    if isinstance(item, str):
                        payload = {"customerName": item}
                        label = f"{req_name}_{idx}_{item.replace(' ', '_')}"
                    elif isinstance(item, dict):
                        payload = item
                        label = f"{req_name}_{idx}"
                    else:
                        logger.warning(f"Skipping invalid item #{idx}: {item}")
                        continue

                    results = client.process_request(label, endpoint, payload)
                    all_results[label] = results
            else:
                # Single mode: payload defined directly in config.yml
                payload = req_config.get('payload', {})
                results = client.process_request(req_name, endpoint, payload)
                all_results[req_name] = results

        # 6. Blob upload & cleanup (if enabled)
        if blob_mgr.upload_enabled:
            logger.info("")
            logger.info("=" * 60)
            logger.info("Blob Storage Upload")
            logger.info("=" * 60)
            total_uploaded = 0
            total_upload_failed = 0

            for name, res in all_results.items():
                request_folder = res.get('request_folder')
                if not request_folder or not os.path.isdir(request_folder):
                    logger.warning(f"  Skipping blob upload for {name}: folder not found")
                    continue

                upload_result = blob_mgr.upload_request_folder(request_folder, name)
                total_uploaded += upload_result['uploaded']
                total_upload_failed += upload_result['failed']

                # Post-upload action only if all uploads succeeded for this request
                if upload_result['failed'] == 0 and upload_result['uploaded'] > 0:
                    blob_mgr.post_upload_cleanup(request_folder)
                elif upload_result['failed'] > 0:
                    logger.warning(f"  Skipping post-upload action for {name} due to upload failures")

            logger.info(f"  Blob totals: {total_uploaded} uploaded, {total_upload_failed} failed")

        # 7. Final summary
        client.log_final_summary(all_results)

        logger.info("=" * 60)
        logger.info("Process Completed Successfully")
        logger.info("=" * 60)
        sys.exit(0)

    except Exception as e:
        logger.critical("=" * 60)
        logger.critical(f"Process Failed: {e}")
        logger.critical("=" * 60)
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)