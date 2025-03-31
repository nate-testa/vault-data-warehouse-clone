from shared.logger import get_logger
from shared.id_map import IDMapFunctions
from shared.association import Association

import json
import requests
import constants

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
        'Authorization': F'Bearer {constants.hs_token}'
    }

    def api_log(self, res, success_code, action_type, batch, log_failure=True, failure_addon=''):
        if res.status_code == success_code:
            logger.debug(F'"METHOD": "{res.request.method}", '
                        F'"STATUS_CODE": "{res.status_code}",'
                        F'"URL": "{res.url}"')
            

            IDMapFunctions.action_router(action_type, batch, res.json())
        
        else:
            if log_failure:
                logger.error(F'"METHOD": "{res.request.method}", '
                            F'"STATUS_CODE": "{res.status_code}",'
                            F'"URL": "{res.url}",'
                            F'"FAIL RESPONSE": "{res.text}"'
                            F'{failure_addon}')
                res = None

        return res

    def unit_create_record(self, object_type, payload):
        endpoint = F'https://api.hubapi.com/crm/v3/objects/{object_type}'
        res = requests.post(url=endpoint, data=json.dumps(payload, default=str), headers=self.headers, timeout=120)
        if object_type == 'contacts' and 'Contact already exists' in res.text:
            if payload['properties']['email']:
                del payload['properties']['email']
            return self.unit_create_record(object_type, payload)
        # Include payload in failure message.
        return self.api_log(res, 201, self.action_type, batch=False, failure_addon=F',"PAYLOAD": {payload}')

    def batch_create_records(self, object_type, payload):
        endpoint = F'https://api.hubapi.com/crm/v3/objects/{object_type}/batch/create'
        res = requests.post(url=endpoint, data=json.dumps(payload, default=str), headers=self.headers, timeout=120)
        # Run the logger to check for failure, but do not print a failure log.
        return self.api_log(res, 201, self.action_type, batch=True, log_failure=False)

    def unit_update_record(self, object_type, payload):
        endpoint = F"https://api.hubapi.com/crm/v3/objects/{object_type}/{payload['id']}"
        res = requests.patch(url=endpoint, data=json.dumps(payload, default=str), headers=self.headers, timeout=120)
        # Include payload in failure message.
        return self.api_log(res, 200, self.action_type, batch=False, failure_addon=F',"PAYLOAD": {payload}')

    def batch_update_records(self, object_type, payload):
        endpoint = F'https://api.hubapi.com/crm/v3/objects/{object_type}/batch/update'
        res = requests.post(url=endpoint, data=json.dumps(payload, default=str), headers=self.headers, timeout=120)
        # Run the logger to check for failure, but do not print a failure log.
        return self.api_log(res, 200, self.action_type, batch=True, log_failure=False)
    
    def unit_associate_records(self, object_type, payload):
        from_object, to_object, association_id = Association.route_associations(object_type)
        data = [
            {
                'associationCategory': 'USER_DEFINED',
                'associationTypeId': association_id,
            },
        ]
        endpoint = f"{constants.hub_api}/crm/v4/objects/{from_object}/{payload['from']['id']}/associations/{to_object}/{payload['to']['id']}"
        res = requests.put(url=endpoint, data=json.dumps(data, default=str), headers=self.headers, timeout=120)
        # Run the logger to check for failure, but do not print a failure log.
        return self.api_log(res, 201, self.action_type, batch=False, failure_addon=F',"PAYLOAD": {payload}')

    def batch_associate_records(self, object_type, payload):
        from_object, to_object, association_id = Association.route_associations(object_type)
        endpoint = f'{constants.hub_api}/crm/v4/associations/{from_object}/{to_object}/batch/create'
        res = requests.post(url=endpoint, data=json.dumps(payload, default=str), headers=self.headers, timeout=120)
        # Run the logger to check for failure, but do not print a failure log.
        return self.api_log(res, 201, self.action_type, batch=True, log_failure=False)

    def sending_payload_batches(payload, limit=100):
        record_path = next(iter(payload))
        num_records = len(payload[record_path])
        batches = [{record_path: payload[record_path][i: i + limit]}
                for i in range(0, num_records, limit)]
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
        response = requests.get(url=url, headers=RecordsDispatcher.headers, timeout=120)
        id_list = []
        json = response.json()
        return json
        # for result in json['results']:
        #     related_note_id = result['toObjectId']
        #     id_list.append[related_note_id]
        #     return id_list
        # else:
        #     return ''
            

    def dispatch(self, payload):
        """
        Attempts batch requests, retrying with unit requests if a given batch fails.
        """
        num_total = len(payload['inputs'])

        if num_total > self.batch_limit:
            logger.info(F'Breaking {num_total} records into batches of {self.batch_limit}.')
            batches = RecordsDispatcher.sending_payload_batches(payload, self.batch_limit)
            num_batches = len(batches)
            logger.info(F'{num_batches} batch {self.action_type} requests to do.')
        else:
            batches = [payload]
            num_batches = 1
            logger.info(F'1 batch {self.action_type} request to do.')

        for i, batch in enumerate(batches):
            logger.info(F'Working on {self.action_type} batch request {i + 1}/{num_batches}...')

            if not self._batch_request(self.object_type, batch):
                logger.warning(F'Batch {i + 1}/{num_batches} failed. Breaking batch into individual requests...')
                units = batch['inputs']
                num_units = len(units)
                logger.info(F'{num_units} individual {self.action_type} requests to do.')

                for j, unit in enumerate(units):
                    logger.info(F'Working on batch {i + 1}/{num_batches}, unit {self.action_type} request {j + 1}/{num_units}...')
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