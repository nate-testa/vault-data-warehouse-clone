import os
import csv
import json
import time
import pathlib
from datetime import datetime
import requests


class APIClient:
    """Handles authentication and document API calls for OS Document Extract."""

    def __init__(self, config_manager, logger):
        self.cfg = config_manager
        self.logger = logger

        # API config from config.yml
        api_config = self.cfg.config.get('api', {})
        self.pss_url = api_config.get('pss_url', '')
        self.dms_url = api_config.get('dms_url', '')
        self.auth_path = api_config.get('auth_path', '/v2/token/generate')
        self.realm = api_config.get('realm', 'PlatformComponents')
        self.grant_type = api_config.get('grant_type', 'client_credentials')
        self.endpoints = api_config.get('endpoints', {})

        # Download config
        download_config = self.cfg.config.get('download', {})
        self.output_dir = download_config.get('output_dir', 'downloads')
        self.keep_metadata_csv = download_config.get('keep_metadata_csv', True)
        self.timeout = download_config.get('timeout_seconds', 120)
        self.max_retries = download_config.get('max_retries', 3)
        self.retry_delay = download_config.get('retry_delay_seconds', 2)

        # Base output path
        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.output_base = os.path.join(script_dir, self.output_dir)
        os.makedirs(self.output_base, exist_ok=True)

        # Token cache
        self._token = None

        self.logger.info("API Client initialized")
        self.logger.info(f"  PSS URL: {self.pss_url}")
        self.logger.info(f"  DMS URL: {self.dms_url}")
        self.logger.info(f"  Output:  {self.output_base}")

    # -------------------------------------------------------------------------
    # Authentication
    # -------------------------------------------------------------------------
    def authenticate(self):
        """Authenticate via PSS token endpoint and cache the Bearer token."""
        url = f"{self.pss_url}{self.auth_path}"
        self.logger.info(f"Authenticating at {url} ...")

        payload = {
            "grantType": self.grant_type,
            "clientId": self.cfg.get('client_id'),
            "clientSecret": self.cfg.get('client_secret'),
        }
        headers = {
            "realm": self.realm,
            "Content-Type": "application/json",
        }

        resp = requests.post(url, json=payload, headers=headers, timeout=30)
        resp.raise_for_status()

        data = resp.json()

        # Log full auth response (mask the token for security)
        safe_data = {}
        for k, v in data.items():
            if k in ('access_token', 'token', 'refresh_token'):
                safe_data[k] = f"{str(v)[:20]}...({len(str(v))} chars)" if v else v
            else:
                safe_data[k] = v
        self.logger.info(f"  Auth response keys: {list(data.keys())}")
        self.logger.info(f"  Auth response:\n{json.dumps(safe_data, indent=2, default=str)}")

        self._token = data.get("access_token") or data.get("token")
        if not self._token:
            raise ValueError(f"No token in auth response. Keys returned: {list(data.keys())}")

        self.logger.info("  Authentication successful")

    def _auth_headers(self):
        """Return headers with current Bearer token."""
        if not self._token:
            raise RuntimeError("Not authenticated. Call authenticate() first.")
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self._token}",
        }

    # -------------------------------------------------------------------------
    # Document Endpoints
    # -------------------------------------------------------------------------
    def fetch_documents(self, endpoint_key, payload):
        """
        Call a DMS document endpoint and return the JSON response.

        Args:
            endpoint_key: Key from config endpoints (e.g. 'clm001', 'clm002')
            payload: Request body dict
        Returns:
            Parsed JSON response (list of document dicts)
        """
        path = self.endpoints.get(endpoint_key)
        if not path:
            raise ValueError(f"Unknown endpoint key: '{endpoint_key}'. "
                             f"Available: {list(self.endpoints.keys())}")

        url = f"{self.dms_url}{path}"
        self.logger.info(f"Calling {endpoint_key}: POST {url}")
        self.logger.info(f"  Payload: {payload}")

        resp = requests.post(url, json=payload, headers=self._auth_headers(), timeout=self.timeout)
        resp.raise_for_status()

        data = resp.json()
        count = len(data) if isinstance(data, list) else 'N/A'
        self.logger.info(f"  Response: {count} documents returned")
        return data

    # -------------------------------------------------------------------------
    # Process a full request (fetch + download all)
    # -------------------------------------------------------------------------
    def process_request(self, request_name, endpoint_key, payload):
        """
        End-to-end: fetch document list, download each file, save metadata CSV.

        Args:
            request_name: Label for this request (used for folder/CSV naming)
            endpoint_key: Endpoint key (clm001, clm002, etc.)
            payload: Request body dict
        Returns:
            results dict with 'successful', 'failed', 'skipped' lists
        """
        self.logger.info("-" * 60)
        self.logger.info(f"Processing request: {request_name}")
        self.logger.info("-" * 60)

        # Create subfolder per request: downloads/{request_name}_{timestamp}
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        request_folder = os.path.join(self.output_base, f"{request_name}_{timestamp}")
        os.makedirs(request_folder, exist_ok=True)
        docs_folder = os.path.join(request_folder, "documents")
        os.makedirs(docs_folder, exist_ok=True)

        # Fetch document list
        documents = self.fetch_documents(endpoint_key, payload)
        if not isinstance(documents, list):
            self.logger.warning(f"  Expected list, got {type(documents).__name__}. Wrapping.")
            documents = [documents] if documents else []

        results = {'successful': [], 'failed': [], 'skipped': []}

        for idx, doc in enumerate(documents, 1):
            doc_url = (doc.get('documentUrl') or '').strip()
            output_name = build_output_filename(doc, idx)

            if not doc_url:
                self.logger.warning(f"  [{idx}/{len(documents)}] SKIP (no URL): {output_name}")
                results['skipped'].append({'index': idx, 'filename': output_name, 'reason': 'empty documentUrl'})
                continue

            try:
                dest = self._download_presigned(doc_url, docs_folder, output_name, idx, len(documents))
                results['successful'].append({'index': idx, 'filename': output_name, 'path': dest})
            except Exception as e:
                self.logger.error(f"  [{idx}/{len(documents)}] FAIL: {output_name} - {e}")
                results['failed'].append({'index': idx, 'filename': output_name, 'error': str(e)})

        # Save metadata CSV
        if self.keep_metadata_csv and documents:
            csv_path = os.path.join(request_folder, f"{request_name}_metadata.csv")
            self._save_metadata_csv(documents, csv_path)

        self._log_request_summary(request_name, results, len(documents))
        results['request_folder'] = request_folder
        return results

    # -------------------------------------------------------------------------
    # File Download (DMS URLs require Bearer token)
    # -------------------------------------------------------------------------
    def _download_presigned(self, url, dest_folder, output_filename, idx, total):
        """Download from a document URL with retry logic."""
        safe_name = sanitize_filename(output_filename)
        dest = os.path.join(dest_folder, safe_name)

        for attempt in range(1, self.max_retries + 1):
            try:
                self.logger.info(f"  [{idx}/{total}] Downloading (attempt {attempt}): {safe_name}")

                resp = requests.get(
                    url,
                    headers={"Authorization": f"Bearer {self._token}"},
                    timeout=self.timeout,
                    stream=True,
                )
                resp.raise_for_status()

                with open(dest, 'wb') as f:
                    for chunk in resp.iter_content(chunk_size=8192):
                        f.write(chunk)

                size_kb = os.path.getsize(dest) / 1024
                self.logger.info(f"  [{idx}/{total}] OK: {safe_name} ({size_kb:.1f} KB)")
                return dest

            except requests.RequestException as e:
                self.logger.warning(f"  [{idx}/{total}] Attempt {attempt} failed: {e}")
                if attempt < self.max_retries:
                    time.sleep(self.retry_delay)
                else:
                    raise

    # -------------------------------------------------------------------------
    # Metadata CSV
    # -------------------------------------------------------------------------
    def _save_metadata_csv(self, documents, csv_path):
        """Save document metadata to a CSV file."""
        try:
            # Collect all unique keys across documents
            all_keys = []
            for doc in documents:
                for k in doc.keys():
                    if k not in all_keys:
                        all_keys.append(k)

            with open(csv_path, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=all_keys, extrasaction='ignore')
                writer.writeheader()
                for doc in documents:
                    writer.writerow(doc)

            self.logger.info(f"  Metadata CSV saved: {csv_path}")
        except Exception as e:
            self.logger.warning(f"  Failed to save metadata CSV: {e}")

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    def _log_request_summary(self, request_name, results, total_docs):
        """Log summary for a single request."""
        self.logger.info("")
        self.logger.info(f"  --- {request_name} Summary ---")
        self.logger.info(f"  Documents returned: {total_docs}")
        self.logger.info(f"  Downloaded: {len(results['successful'])}")
        self.logger.info(f"  Skipped:    {len(results['skipped'])}")
        self.logger.info(f"  Failed:     {len(results['failed'])}")
        if results['failed']:
            for item in results['failed']:
                self.logger.info(f"    FAIL: {item['filename']} - {item['error']}")
        self.logger.info("")

    def log_final_summary(self, all_results):
        """Log overall summary across all requests."""
        self.logger.info("=" * 70)
        self.logger.info("FINAL SUMMARY")
        self.logger.info("=" * 70)

        total_ok = total_skip = total_fail = 0
        for name, res in all_results.items():
            ok = len(res['successful'])
            skip = len(res['skipped'])
            fail = len(res['failed'])
            total_ok += ok
            total_skip += skip
            total_fail += fail
            self.logger.info(f"  {name:<30} OK: {ok}  Skip: {skip}  Fail: {fail}")

        self.logger.info("-" * 70)
        self.logger.info(f"  {'TOTAL':<30} OK: {total_ok}  Skip: {total_skip}  Fail: {total_fail}")
        self.logger.info("=" * 70)


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def safe_text(value, default, max_len):
    """Normalize and safely truncate text."""
    if value is None:
        return default
    txt = str(value).strip()
    return txt[:max_len] if txt else default


def sanitize_filename(name):
    """Remove characters that can break filenames."""
    return (
        str(name)
        .replace("/", "")
        .replace(":", "")
        .replace("\\", "")
        .replace("?", "")
        .replace("*", "")
        .replace('"', "")
        .replace("<", "")
        .replace(">", "")
        .replace("|", "")
    )


def build_output_filename(doc, index):
    """
    Build a descriptive output filename from document metadata.

    Pattern: {date} {primaryObject} {docType} {docName} dmsId-{id}{ext}

    Works with both clm001 and clm002 response schemas.
    """
    # Date
    raw_date = doc.get('document_date') or doc.get('created_date') or ''
    try:
        dt = datetime.fromisoformat(raw_date.replace('+00:00', '+00:00'))
        date_str = dt.strftime("%Y-%m-%d")
    except (ValueError, AttributeError):
        date_str = "NoDate"

    # Primary object
    primary_obj = safe_text(
        doc.get('primary_object') or doc.get('attached_To'),
        "NoObj", 10
    ).title()

    # Document subtype or type
    doc_type = safe_text(
        doc.get('subtype') or doc.get('document_type'),
        "NoType", 20
    ).title()

    # Document name
    doc_name = safe_text(doc.get('document_name'), "NoName", 25).title()

    # ID (prefer dms_document_id, fall back to aws_document_id)
    doc_id = str(doc.get('dms_document_id') or doc.get('aws_document_id') or index)

    # Extension from file_name, document_fileName, or file_format
    ext = ""
    for field in ('file_name', 'document_fileName'):
        val = doc.get(field)
        if val:
            ext = pathlib.Path(str(val)).suffix
            if ext:
                break
    if not ext:
        fmt = doc.get('file_format')
        if fmt:
            ext = f".{fmt}" if not fmt.startswith('.') else fmt

    filename = f"{date_str} {primary_obj} {doc_type} {doc_name} dmsId-{doc_id}{ext}"
    return sanitize_filename(filename)
