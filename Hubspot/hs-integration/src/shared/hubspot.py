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

logger = get_logger(__name__)

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

    def api_log(self, res, success_code, action_type, batch, log_failure=True, failure_addon=''):
        if res and res.status_code == success_code:
            logger.debug(
                f'"METHOD": "{res.request.method}", '
                f'"STATUS_CODE": "{res.status_code}",'
                f'"URL": "{res.url}"'
            )
            IDMapFunctions.action_router(action_type, batch, res.json())
        else:
            if log_failure and res is not None:
                logger.error(
                    f'"METHOD": "{res.request.method}", '
                    f'"STATUS_CODE": "{res.status_code}",'
                    f'"URL": "{res.url}",'
                    f'"FAIL RESPONSE": "{res.text}"'
                    f'{failure_addon}'
                )
            # If response is None or not successful, return None.
            res = None

        return res

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
            log_failure=False
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
            log_failure=False
        )

    def unit_associate_records(self, object_type, payload):
        from_object, to_object, association_id = Association.route_associations(object_type)
        data_body = [
            {
                'associationCategory': 'USER_DEFINED',
                'associationTypeId': association_id,
            },
        ]
        endpoint = f'{constants.hub_api}/crm/v4/objects/{from_object}/{payload["from"]["id"]}/associations/{to_object}/{payload["to"]["id"]}'
        max_attempts = 3
        delay_seconds = 3
        res = None

        for attempt in range(max_attempts):
            try:
                res = requests.put(
                    url=endpoint,
                    data=json.dumps(data_body, default=str),
                    headers=self.headers,
                    timeout=120
                )
                break
            except (RemoteDisconnected, ConnectionError, Timeout, RequestException) as exc:
                logger.warning(
                    f'unit_associate_records failed (attempt {attempt+1}) with error: {exc}. '
                    f'Retrying in {delay_seconds} seconds...'
                )
                time.sleep(delay_seconds)
                delay_seconds *= 2

        return self.api_log(
            res,
            201,
            self.action_type,
            batch=False,
            failure_addon=f',"PAYLOAD": {payload}'
        )

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
            logger.info(f'1 batch {self.action_type} request to do.')

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
