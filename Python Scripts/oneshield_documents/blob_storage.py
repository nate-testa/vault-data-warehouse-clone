""" 
Azure Blob Storage upload module for OS Document Extract.

Handles uploading downloaded documents to Azure Blob Storage
and post-upload local file cleanup (keep / delete / archive).

Uses Airflow WasbHook for blob uploads (following broker_goal pattern).
Storage account credentials are configured in the Airflow connection.
"""

import os
import shutil
from datetime import datetime


class BlobStorageManager:
    """Upload files to Azure Blob Storage and manage post-upload actions."""

    def __init__(self, config_manager, logger):
        self.logger = logger
        self.cfg = config_manager

        # Blob config from config.yml
        blob_config = self.cfg.config.get('blob_storage', {})
        self.upload_enabled = blob_config.get('upload_enabled', False)
        self.post_upload_action = blob_config.get('post_upload_action', 'keep')
        self.archive_dir = blob_config.get('archive_dir', 'archive')
        self.wasb_conn_id = blob_config.get('wasb_conn_id', '').strip()

        # Container: secret (Key Vault / static) takes priority, then config.yml fallback
        secret_container = (self.cfg.get('blob_container') or '').strip()
        config_container = blob_config.get('container', 'outbound-oneshield-documents')
        self.container_name = secret_container if secret_container else config_container

        self.folder = blob_config.get('folder', 'extracted_documents').strip('/')

        # Blob hook / client (lazy init)
        self._wasb_hook = None
        self._blob_service_client = None

        if self.upload_enabled:
            self.logger.info("Blob Storage upload: ENABLED")
            self.logger.info(f"  Container: {self.container_name}")
            self.logger.info(f"  Folder:    {self.folder}")
            if not self.wasb_conn_id:
                self.logger.warning("  No wasb_conn_id configured - uploads will fail!")
            else:
                self.logger.info(f"  Auth:      WasbHook (conn_id={self.wasb_conn_id})")
            self.logger.info(f"  Post-upload action: {self.post_upload_action}")
        else:
            self.logger.info("Blob Storage upload: DISABLED (files stay in downloads/)")

    def _init_connection(self):
        """Initialize blob connection using Airflow WasbHook."""
        if self._blob_service_client is not None:
            return

        if not self.wasb_conn_id:
            raise ValueError(
                "Blob upload requires wasb_conn_id to be configured. "
                "Set blob_storage.wasb_conn_id in config.yml (e.g., 'azure_blob_storage')"
            )

        try:
            from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
            self._wasb_hook = WasbHook(wasb_conn_id=self.wasb_conn_id)
            # Get blob service client from WasbHook
            self._blob_service_client = self._wasb_hook.get_conn()
            self.logger.info(f"  Connected via WasbHook (conn_id={self.wasb_conn_id})")
        except ImportError:
            raise ImportError(
                "Airflow WasbHook not available. Install with: pip install apache-airflow-providers-microsoft-azure"
            )
        except Exception as e:
            raise ConnectionError(f"Failed to connect via WasbHook: {e}")

    def _upload_file(self, local_path, blob_name):
        """Upload a single file to blob storage using WasbHook.load_file()."""
        self._wasb_hook.load_file(
            file_path=local_path,
            container_name=self.container_name,
            blob_name=blob_name,
        )

    def upload_request_folder(self, request_folder, request_name):
        """
        Upload all files from a request's download folder to Blob Storage.

        Blob path structure: {folder}/{request_name}/{filename}
        E.g.: documents/clm001_claims_20260224_182048/documents/file.docx
              documents/clm001_claims_20260224_182048/clm001_claims_metadata.csv

        Args:
            request_folder: Local path to the request output folder
            request_name: Label for this request (used in blob path)

        Returns:
            dict with 'uploaded' count and 'failed' count
        """
        if not self.upload_enabled:
            return {'uploaded': 0, 'failed': 0}

        self.logger.info(f"  Uploading to blob: {self.container_name}/{self.folder}/...")

        self._init_connection()

        # Walk the request folder and upload all files
        uploaded = 0
        failed = 0
        folder_basename = os.path.basename(request_folder)

        for root, _dirs, files in os.walk(request_folder):
            for filename in files:
                local_path = os.path.join(root, filename)
                # Build relative path from request_folder root
                rel_path = os.path.relpath(local_path, request_folder)
                blob_path = f"{self.folder}/{folder_basename}/{rel_path}"

                try:
                    self._upload_file(local_path, blob_path)

                    size_kb = os.path.getsize(local_path) / 1024
                    self.logger.info(f"    Uploaded: {blob_path} ({size_kb:.1f} KB)")
                    uploaded += 1

                except Exception as e:
                    self.logger.error(f"    FAIL upload: {blob_path} - {e}")
                    failed += 1

        self.logger.info(f"  Blob upload complete: {uploaded} uploaded, {failed} failed")
        return {'uploaded': uploaded, 'failed': failed}

    def post_upload_cleanup(self, request_folder):
        """
        Handle local files after successful blob upload.

        Actions:
            'keep'    - do nothing (files stay in downloads/)
            'delete'  - remove the entire request folder
            'archive' - move request folder to archive/ with timestamp
        """
        if not self.upload_enabled:
            return

        action = self.post_upload_action

        if action == 'keep':
            self.logger.info(f"  Post-upload: keeping local files in {request_folder}")
            return

        if action == 'delete':
            try:
                shutil.rmtree(request_folder)
                self.logger.info(f"  Post-upload: deleted local folder {request_folder}")
            except Exception as e:
                self.logger.warning(f"  Post-upload: failed to delete {request_folder} - {e}")
            return

        if action == 'archive':
            try:
                # Archive dir is relative to the script directory
                script_dir = os.path.dirname(os.path.abspath(__file__))
                archive_base = os.path.join(script_dir, self.archive_dir)
                os.makedirs(archive_base, exist_ok=True)

                folder_name = os.path.basename(request_folder)
                archive_dest = os.path.join(archive_base, folder_name)

                # Avoid collision
                if os.path.exists(archive_dest):
                    ts = datetime.now().strftime("%H%M%S")
                    archive_dest = f"{archive_dest}_{ts}"

                shutil.move(request_folder, archive_dest)
                self.logger.info(f"  Post-upload: archived to {archive_dest}")
            except Exception as e:
                self.logger.warning(f"  Post-upload: failed to archive {request_folder} - {e}")
            return

        self.logger.warning(f"  Unknown post_upload_action: '{action}'. Keeping files.")
