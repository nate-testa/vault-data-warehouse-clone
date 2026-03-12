import json
import time
import requests

# Explicitly import RemoteDisconnected to catch it separately if needed
from http.client import RemoteDisconnected
from requests.exceptions import ConnectionError, Timeout, RequestException

import constants
from shared.logger import get_logger
from shared.id_map import IDMapFunctions
from shared.association import Association
from shared.error_reporter import ErrorReporter

logger = get_logger(__name__)
error_reporter = ErrorReporter()

class RecordsDispatcher:
    # Batch limit according to HubSpot API documentation.
    batch_limit = 100

    headers = {
        'User-Agent': 'python-requests/2.32.3',
        'Accept-Encoding': 'gzip, deflate',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'content-type': 'application/json',
        'Authorization': f'Bearer {constants.hs_token}'
    }

    def api_log(self, res, success_code, action_type, batch, log_failure=True, failure_addon='', request_payload=None):
        if res and res.status_code == success_code:
            logger.debug(
                f'"METHOD": "{res.request.method}", '
                f'"STATUS_CODE": "{res.status_code}",'
                f'"URL": "{res.url}"'
            )
            IDMapFunctions.action_router(action_type, batch, res.json(), request_payload)
            
            # Update success statistics
            object_base = action_type.replace('_create', '').replace('_update', '')
            if '_create' in action_type:
                count = len(res.json().get('results', [])) if batch else 1
                error_reporter.update_stats(object_base, 'created', count)
            elif '_update' in action_type:
                count = len(res.json().get('results', [])) if batch else 1
                error_reporter.update_stats(object_base, 'updated', count)
        else:
            if log_failure and res is not None:
                logger.error(
                    f'"METHOD": "{res.request.method}", '
                    f'"STATUS_CODE": "{res.status_code}",'
                    f'"URL": "{res.url}",'
                    f'"FAIL RESPONSE": "{res.text}"'
                    f'{failure_addon}'
                )
                
                # Capture error in error reporter
                error_category = self._categorize_error(res)
                error_details = {
                    'method': res.request.method,
                    'status_code': res.status_code,
                    'url': res.url,
                    'response': res.text[:500],  # Limit response length
                    'action_type': action_type
                }
                error_reporter.add_error(error_category, res.text[:200], error_details)
                
                # Update failure statistics
                object_base = action_type.replace('_create', '').replace('_update', '').replace('_associations', '').replace('-association', '')
                if 'association' in action_type:
                    error_reporter.update_stats('associations', 'failed', 1)
                else:
                    error_reporter.update_stats(object_base, 'failed', 1)
            # If response is None or not successful, return None.
            res = None

        return res
    
    def _categorize_error(self, res):
        """Categorize error based on response"""
        if res is None:
            return 'NETWORK_ERROR'
        
        text = res.text.lower()
        
        if 'association_user_config_limit_exceeded' in text:
            return 'ASSOCIATION_LIMIT'
        elif 'property' in text and 'does not exist' in text:
            return 'PROPERTY_NOT_FOUND'
        elif 'contact already exists' in text:
            return 'DUPLICATE_CONTACT'
        elif 'already has that value' in text:
            return 'DUPLICATE_VALUE'
        elif '"category":"validation_error"' in text:
            return 'VALIDATION_ERROR'
        elif res.status_code == 429:
            return 'RATE_LIMIT'
        elif res.status_code == 400:
            return 'BAD_REQUEST'
        elif res.status_code == 404:
            return 'NOT_FOUND'
        elif res.status_code >= 500:
            return 'SERVER_ERROR'
        else:
            return 'OTHER_ERROR'

    def unit_create_record(self, object_type, payload):
        endpoint = f'https://api.hubapi.com/crm/v3/objects/{object_type}'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.post(
                    url=endpoint,
                    data=json.dumps(payload, default=str),
                    headers=self.headers,
                    timeout=120
                )

                # If "Contact already exists" is found, remove 'email' from payload and retry once
                if object_type == 'contacts' and 'Contact already exists' in res.text:
                    if payload['properties'].get('email'):
                        del payload['properties']['email']
                    return self.unit_create_record(object_type, payload)

                break  # success or non-200 response, but got a response

            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'unit_create_record failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                error_reporter.add_warning('NETWORK_RETRY', f'Retry attempt {attempt+1} for unit_create_record: {exc}')
                time.sleep(delay_seconds)
                delay_seconds *= 2

        # Log success/fail
        return self.api_log(
            res,
            201,
            self.action_type,
            batch=False,
            failure_addon=f',"PAYLOAD": {payload}'
        )

    def batch_create_records(self, object_type, payload):
        endpoint = f'https://api.hubapi.com/crm/v3/objects/{object_type}/batch/create'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.post(
                    url=endpoint,
                    data=json.dumps(payload, default=str),
                    headers=self.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'batch_create_records failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        return self.api_log(
            res,
            201,
            self.action_type,
            batch=True,
            log_failure=False,
            request_payload=payload
        )

    def unit_update_record(self, object_type, payload):
        endpoint = f'https://api.hubapi.com/crm/v3/objects/{object_type}/{payload["id"]}'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.patch(
                    url=endpoint,
                    data=json.dumps(payload, default=str),
                    headers=self.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'unit_update_record failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        return self.api_log(
            res,
            200,
            self.action_type,
            batch=False,
            failure_addon=f',"PAYLOAD": {payload}'
        )

    def batch_update_records(self, object_type, payload):
        endpoint = f'https://api.hubapi.com/crm/v3/objects/{object_type}/batch/update'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.post(
                    url=endpoint,
                    data=json.dumps(payload, default=str),
                    headers=self.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'batch_update_records failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        return self.api_log(
            res,
            200,
            self.action_type,
            batch=True,
            log_failure=False,
            request_payload=payload
        )

    def get_existing_associations(self, from_object, from_id, to_object, association_id):
        """Get existing associations of a specific type from an object."""
        all_assocs = self.get_all_associations(from_object, from_id, to_object)
        matching = [
            r for r in all_assocs
            if any(
                t.get('typeId') == association_id
                for t in r.get('associationTypes', [])
            )
        ]
        return matching

    def get_all_associations(self, from_object, from_id, to_object):
        """Get ALL existing associations from an object to a target object type, regardless of association type."""
        endpoint = f'{constants.hub_api}/crm/v4/objects/{from_object}/{from_id}/associations/{to_object}'
        try:
            res = requests.get(
                url=endpoint,
                headers=self.headers,
                timeout=120
            )
            if res.status_code == 200:
                return res.json().get('results', [])
            return []
        except Exception as exc:
            logger.warning(f'Failed to get all associations for {from_object} {from_id} -> {to_object}: {exc}')
            return []

    def _classify_association_conflict(self, all_associations, target_to_id, association_id):
        """Classify association conflict into specific failure scenarios.

        Returns:
            tuple: (conflict_type, details_dict)
            conflict_type is one of:
              - 'ALREADY_CORRECT': target association already exists with correct type
              - 'ASSOCIATION_NEEDS_REPLACEMENT': same-type association exists to different target
              - 'ASSOCIATION_CROSS_TYPE_CONFLICT': different association type is occupying the slot
              - None: no conflict detected
        """
        same_type_assocs = []
        other_type_assocs = []
        target_to_id_str = str(target_to_id)

        for assoc in all_associations:
            to_obj_id = str(assoc.get('toObjectId', ''))
            type_ids = [t.get('typeId') for t in assoc.get('associationTypes', [])]
            categories = [t.get('category', 'UNKNOWN') for t in assoc.get('associationTypes', [])]

            if association_id in type_ids:
                if to_obj_id == target_to_id_str:
                    return 'ALREADY_CORRECT', {
                        'existing_to_id': to_obj_id,
                        'type_ids': type_ids,
                        'categories': categories
                    }
                else:
                    same_type_assocs.append({
                        'to_id': to_obj_id,
                        'type_ids': type_ids,
                        'categories': categories
                    })
            else:
                other_type_assocs.append({
                    'to_id': to_obj_id,
                    'type_ids': type_ids,
                    'categories': categories
                })

        if same_type_assocs:
            return 'ASSOCIATION_NEEDS_REPLACEMENT', {
                'same_type_associations': same_type_assocs,
                'other_type_associations': other_type_assocs
            }

        if other_type_assocs:
            return 'ASSOCIATION_CROSS_TYPE_CONFLICT', {
                'blocking_associations': other_type_assocs
            }

        return None, {}

    def delete_association(self, from_object, from_id, to_object, to_id, association_id):
        """Delete a specific association."""
        endpoint = f'{constants.hub_api}/crm/v4/objects/{from_object}/{from_id}/associations/{to_object}/{to_id}'
        data_body = [
            {
                'associationCategory': 'USER_DEFINED',
                'associationTypeId': association_id,
            },
        ]
        try:
            res = requests.delete(
                url=endpoint,
                data=json.dumps(data_body, default=str),
                headers=self.headers,
                timeout=120
            )
            if res.status_code == 204:
                logger.info(f'Deleted existing association: {from_object} {from_id} -> {to_object} {to_id}')
                return True
            else:
                logger.warning(f'Failed to delete association. Status: {res.status_code}, Response: {res.text}')
                return False
        except Exception as exc:
            logger.warning(f'Failed to delete association: {exc}')
            return False

    def unit_associate_records(self, object_type, payload):
        from_object, to_object, association_id = Association.route_associations(object_type)
        from_id = payload["from"]["id"]
        to_id = payload["to"]["id"]
        data_body = [
            {
                'associationCategory': 'USER_DEFINED',
                'associationTypeId': association_id,
            },
        ]
        endpoint = f'{constants.hub_api}/crm/v4/objects/{from_object}/{from_id}/associations/{to_object}/{to_id}'
        max_attempts = 3
        delay_seconds = 3
        res = None
        
        # Proactive producer association change detection
        # For quote-producer and policy-producer associations (environment-agnostic)
        producer_association_ids = [
            Association.association_type_id['quote-producer'],
            Association.association_type_id['policy-producer']
        ]
        if constants.CLEAN_CHANGED_PRODUCER_ASSOCIATIONS and association_id in producer_association_ids:
            existing = self.get_existing_associations(
                from_object, from_id, to_object, association_id
            )
            
            # Check if there's an existing producer association to a DIFFERENT producer
            for assoc in existing:
                old_producer_id = str(assoc.get('toObjectId'))
                new_producer_id = str(to_id)
                
                logger.info(
                    f'Producer association check for {from_object} {from_id}: '
                    f'Existing producer: {old_producer_id}, Requested producer: {new_producer_id}'
                )
                
                if old_producer_id and old_producer_id != new_producer_id:
                    logger.info(
                        f'Producer change detected for {from_object} {from_id}: '
                        f'Old producer contact: {old_producer_id}, New producer contact: {new_producer_id}. '
                        f'Deleting old association...'
                    )
                    
                    delete_success = self.delete_association(
                        from_object, from_id, to_object, old_producer_id, association_id
                    )
                    
                    if delete_success:
                        logger.info(f'Successfully deleted old producer association to contact {old_producer_id}')
                        error_reporter.update_stats('associations', 'producer_reassigned', 1)
                    else:
                        logger.warning(f'Failed to delete old producer association to contact {old_producer_id}')
                elif old_producer_id == new_producer_id:
                    logger.info(
                        f'Producer association already correct for {from_object} {from_id} '
                        f'(contact {old_producer_id}). Skipping creation.'
                    )
                    return None

        # --- Pre-flight validation (#4): Check existing associations before attempting PUT ---
        # Only for association types with a limit of 1 (configured in constants.LIMITED_ASSOCIATION_TYPES)
        limited_types = getattr(constants, 'LIMITED_ASSOCIATION_TYPES', [])
        if getattr(constants, 'PREFLIGHT_ASSOCIATION_CHECK', False) and association_id in limited_types:
            all_existing = self.get_all_associations(from_object, from_id, to_object)
            if all_existing:
                conflict_type, conflict_details = self._classify_association_conflict(
                    all_existing, to_id, association_id
                )

                if conflict_type == 'ALREADY_CORRECT':
                    logger.debug(
                        f'ASSOCIATION_ALREADY_CORRECT: {from_object} {from_id} -> {to_object} {to_id} '
                        f'(type {association_id}). Skipping.'
                    )
                    error_reporter.update_stats('associations', 'already_correct', 1)
                    return None

                elif conflict_type == 'ASSOCIATION_CROSS_TYPE_CONFLICT':
                    blocking = conflict_details.get('blocking_associations', [])
                    blocking_summary = [
                        f"to={b['to_id']} types={b['type_ids']} categories={b['categories']}"
                        for b in blocking
                    ]
                    logger.warning(
                        f'PREFLIGHT_CROSS_TYPE_CONFLICT: {from_object} {from_id} -> {to_object} {to_id} '
                        f'(type {association_id}). Slot occupied by different association type(s). '
                        f'Blocking associations: {blocking_summary}. '
                        f'Skipping PUT — this call would fail with ASSOCIATION_USER_CONFIG_LIMIT_EXCEEDED.'
                    )
                    error_reporter.add_error(
                        'ASSOCIATION_CROSS_TYPE_CONFLICT',
                        f'{from_object} {from_id}: slot blocked by other type(s)',
                        {
                            'from_object': from_object, 'from_id': from_id,
                            'to_object': to_object, 'to_id': to_id,
                            'association_type_id': association_id,
                            'blocking_associations': blocking,
                            'fix': 'Remove or reconfigure blocking association type, or increase HubSpot association limit'
                        }
                    )
                    error_reporter.update_stats('associations', 'cross_type_conflict', 1)
                    return None

                elif conflict_type == 'ASSOCIATION_NEEDS_REPLACEMENT':
                    same_type = conflict_details.get('same_type_associations', [])
                    other_type = conflict_details.get('other_type_associations', [])
                    logger.warning(
                        f'PREFLIGHT_NEEDS_REPLACEMENT: {from_object} {from_id} -> {to_object} {to_id} '
                        f'(type {association_id}). Same-type association exists to different target(s): '
                        f'{[a["to_id"] for a in same_type]}. '
                        f'Other types on this object: {[(a["to_id"], a["type_ids"]) for a in other_type]}. '
                        f'Will attempt PUT (may need REPLACE_ASSOCIATIONS_ON_LIMIT=True to succeed).'
                    )
                    error_reporter.update_stats('associations', 'needs_replacement', 1)

        for attempt in range(max_attempts):
            try:
                res = requests.put(
                    url=endpoint,
                    data=json.dumps(data_body, default=str),
                    headers=self.headers,
                    timeout=120
                )
                
                # Check if we hit the association limit error
                if res.status_code == 400 and 'ASSOCIATION_USER_CONFIG_LIMIT_EXCEEDED' in res.text:
                    # --- Enhanced diagnostics (#1 & #2): Only for limited types ---
                    limited_types = getattr(constants, 'LIMITED_ASSOCIATION_TYPES', [])
                    if association_id in limited_types:
                        # Fetch ALL associations, not just our type
                        all_associations = self.get_all_associations(from_object, from_id, to_object)
                        conflict_type, conflict_details = self._classify_association_conflict(
                            all_associations, to_id, association_id
                        )

                        # Build a full picture of what's on this object
                        assoc_summary = []
                        for assoc in all_associations:
                            a_to_id = assoc.get('toObjectId')
                            a_types = [
                                {'typeId': t.get('typeId'), 'category': t.get('category', 'N/A'), 'label': t.get('label', 'N/A')}
                                for t in assoc.get('associationTypes', [])
                            ]
                            assoc_summary.append({'to_id': a_to_id, 'types': a_types})

                        if conflict_type == 'ASSOCIATION_CROSS_TYPE_CONFLICT':
                            blocking = conflict_details.get('blocking_associations', [])
                            logger.warning(
                                f'ASSOCIATION_CROSS_TYPE_CONFLICT: {from_object} {from_id} -> {to_object} {to_id} '
                                f'(requested type {association_id}). '
                                f'No same-type association exists, but a different association type is using the slot. '
                                f'Blocking associations: {blocking}. '
                                f'ALL associations on this object: {assoc_summary}. '
                                f'FIX: Remove the blocking association or increase the HubSpot association limit for this type.'
                            )
                            error_reporter.add_error(
                                'ASSOCIATION_CROSS_TYPE_CONFLICT',
                                f'{from_object} {from_id}: slot blocked by type(s) {[b["type_ids"] for b in blocking]}',
                                {
                                    'from_object': from_object, 'from_id': from_id,
                                    'to_object': to_object, 'to_id': to_id,
                                    'association_type_id': association_id,
                                    'conflict_type': 'CROSS_TYPE',
                                    'blocking_associations': blocking,
                                    'all_associations': assoc_summary,
                                    'fix': 'Remove blocking association type or increase limit'
                                }
                            )
                            error_reporter.update_stats('associations', 'cross_type_conflict', 1)

                        elif conflict_type == 'ASSOCIATION_NEEDS_REPLACEMENT':
                            same_type = conflict_details.get('same_type_associations', [])
                            logger.warning(
                                f'ASSOCIATION_NEEDS_REPLACEMENT: {from_object} {from_id} -> {to_object} {to_id} '
                                f'(type {association_id}). '
                                f'Same-type association already exists to different target(s): '
                                f'{[a["to_id"] for a in same_type]}. '
                                f'ALL associations on this object: {assoc_summary}. '
                                f'FIX: Set REPLACE_ASSOCIATIONS_ON_LIMIT=True to auto-replace, or manually update in HubSpot.'
                            )
                            error_reporter.add_error(
                                'ASSOCIATION_NEEDS_REPLACEMENT',
                                f'{from_object} {from_id}: same-type assoc to {[a["to_id"] for a in same_type]}',
                                {
                                    'from_object': from_object, 'from_id': from_id,
                                    'to_object': to_object, 'to_id': to_id,
                                    'association_type_id': association_id,
                                    'conflict_type': 'SAME_TYPE',
                                    'existing_same_type': same_type,
                                    'all_associations': assoc_summary,
                                    'fix': 'Set REPLACE_ASSOCIATIONS_ON_LIMIT=True'
                                }
                            )
                            error_reporter.update_stats('associations', 'needs_replacement', 1)

                        else:
                            # Fallback: couldn't determine conflict type
                            logger.warning(
                                f'ASSOCIATION_LIMIT_UNKNOWN: {from_object} {from_id} -> {to_object} {to_id} '
                                f'(type {association_id}). Limit exceeded but conflict type unknown. '
                                f'ALL associations on this object: {assoc_summary}'
                            )
                            error_reporter.add_error(
                                'ASSOCIATION_LIMIT',
                                f'{from_object} {from_id}: limit exceeded (unknown conflict)',
                                {
                                    'from_object': from_object, 'from_id': from_id,
                                    'to_object': to_object, 'to_id': to_id,
                                    'association_type_id': association_id,
                                    'all_associations': assoc_summary
                                }
                            )
                    else:
                        # Non-limited type hit limit — log basic info without extra GET calls
                        logger.warning(
                            f'ASSOCIATION_LIMIT: {from_object} {from_id} -> {to_object} {to_id} '
                            f'(type {association_id}). Limit exceeded. '
                            f'This type is not in LIMITED_ASSOCIATION_TYPES — no detailed diagnostics.'
                        )
                        error_reporter.add_error(
                            'ASSOCIATION_LIMIT',
                            f'{from_object} {from_id}: limit exceeded for type {association_id}',
                            {
                                'from_object': from_object, 'from_id': from_id,
                                'to_object': to_object, 'to_id': to_id,
                                'association_type_id': association_id
                            }
                        )
                    
                    # Only delete and replace if configured to do so
                    if constants.REPLACE_ASSOCIATIONS_ON_LIMIT:
                        logger.info('REPLACE_ASSOCIATIONS_ON_LIMIT is True. Replacing existing association...')
                        
                        # Delete existing associations of this specific type
                        existing_same_type = self.get_existing_associations(
                            from_object, from_id, to_object, association_id
                        )
                        for assoc in existing_same_type:
                            old_to_id = assoc.get('toObjectId')
                            if old_to_id and str(old_to_id) != str(to_id):
                                self.delete_association(
                                    from_object, from_id, to_object, old_to_id, association_id
                                )
                        
                        # Retry the association creation
                        res = requests.put(
                            url=endpoint,
                            data=json.dumps(data_body, default=str),
                            headers=self.headers,
                            timeout=120
                        )
                    else:
                        logger.info(
                            'REPLACE_ASSOCIATIONS_ON_LIMIT is False. Skipping association creation. '
                            'Set constants.REPLACE_ASSOCIATIONS_ON_LIMIT = True to automatically replace.'
                        )
                
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'unit_associate_records failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        result = self.api_log(
            res,
            201,
            self.action_type,
            batch=False,
            failure_addon=f',"PAYLOAD": {payload}'
        )
        
        # Track successful association
        if result is not None:
            error_reporter.update_stats('associations', 'created', 1)
        
        return result

    def batch_associate_records(self, object_type, payload):
        from_object, to_object, association_id = Association.route_associations(object_type)
        endpoint = f'{constants.hub_api}/crm/v4/associations/{from_object}/{to_object}/batch/create'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.post(
                    url=endpoint,
                    data=json.dumps(payload, default=str),
                    headers=self.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'batch_associate_records failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        return self.api_log(
            res,
            201,
            self.action_type,
            batch=True,
            log_failure=False
        )

    def sending_payload_batches(payload, limit=100):
        record_path = next(iter(payload))
        num_records = len(payload[record_path])
        batches = [
            {record_path: payload[record_path][i: i + limit]}
            for i in range(0, num_records, limit)
        ]
        return batches

    def __init__(self, object_type, action_type, unit_request_function, batch_request_function):
        self.object_type = object_type
        self.action_type = action_type
        self._unit_request = unit_request_function
        self._batch_request = batch_request_function
        return

    def get_related_notes(parent_id):
        endpoint = f'crm/v4/objects/companies/{parent_id}/associations/notes'
        url = f"{constants.hub_api}/{endpoint}"

        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.get(
                    url=url,
                    headers=RecordsDispatcher.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'get_related_notes failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        if not res:
            return {}

        return res.json()

    def dispatch(self, payload):
        """
        Attempts batch requests, retrying with unit requests if a given batch fails.
        """
        num_total = len(payload['inputs'])

        if num_total > self.batch_limit:
            logger.info(f'Breaking {num_total} records into batches of {self.batch_limit}.')
            batches = RecordsDispatcher.sending_payload_batches(payload, self.batch_limit)
            num_batches = len(batches)
            logger.info(f'{num_batches} batch {self.action_type} requests to do.')
        else:
            batches = [payload]
            num_batches = 1
            logger.info(f'1 batch {self.action_type} request to do ({num_total} records).')

        for i, batch in enumerate(batches):
            logger.info(f'Working on {self.action_type} batch request {i + 1}/{num_batches}...')

            if not self._batch_request(self.object_type, batch):
                logger.warning(
                    f'Batch {i + 1}/{num_batches} failed. Breaking batch into individual requests...'
                )
                units = batch['inputs']
                num_units = len(units)
                logger.info(f'{num_units} individual {self.action_type} requests to do.')

                for j, unit in enumerate(units):
                    logger.info(
                        f'Working on batch {i + 1}/{num_batches}, '
                        f'unit {self.action_type} request {j + 1}/{num_units}...'
                    )
                    self._unit_request(self.object_type, unit)

        return

class CreateRecordsHandler(RecordsDispatcher):
    def __init__(self, object_type, action_type):
        super().__init__(object_type, action_type, self.unit_create_record, self.batch_create_records)
        return

class UpdateRecordsHandler(RecordsDispatcher):
    def __init__(self, object_type, action_type):
        super().__init__(object_type, action_type, self.unit_update_record, self.batch_update_records)
        return

class AssociationHandler(RecordsDispatcher):
    def __init__(self, object_type, action_type):
        super().__init__(object_type, action_type, self.unit_associate_records, self.batch_associate_records)
        return
