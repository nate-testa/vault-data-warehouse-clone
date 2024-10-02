import requests
import hashlib
import hmac
import base64
import json
import logging
from datetime import datetime
from urllib.parse import urlencode


# Parameters
P_SECRET = 'CJNWgmHUMiQnpRFJoZvb'
P_KEY = 'vault_us_api'
P_BASE_URL = 'https://test.snapsheetvice.com'


class SnapsheetAPI:

    def __init__(self, secret=P_SECRET, key=P_KEY, base_url=P_BASE_URL, logger=None):
        self.secret = secret
        self.key = key
        self.base_url = base_url
        self.logger = logger or logging.getLogger(__name__)

    def _generate_headers(self, method, path, payload='', content_type='application/json', Accept='application/vnd.api+json'):
        timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        sha256_payload = hashlib.sha256(payload.encode('utf-8')).hexdigest()
        canonical_string = f"{method.upper()}{path}{timestamp}{sha256_payload}"
        signature = hmac.new(self.secret.encode('utf-8'), canonical_string.encode('utf-8'), hashlib.sha256).digest()
        authorization = base64.b64encode(signature).decode('utf-8').strip()
        headers = {
            'Content-Type': content_type,
            'Accept': Accept,
            'Timestamp': timestamp,
            'X-SSM-Key': self.key,
            'X-SSM-Authorization': authorization
        }

        return headers

    def _post_request(self, url, headers, data):
        try:
            # Log request
            self.logger.info(f"POST Request URL: {url}")
            self.logger.debug(f"POST Request Headers: {headers}")
            self.logger.debug(f"POST Request Data: {data}")

            # Create request
            response = requests.post(url, headers=headers, data=data)
            
            # Log response
            self.logger.debug(f"POST Response status_code: {response.status_code}")
            self.logger.debug(f"POST Response headers: {response.headers}")
            self.logger.debug(f"POST Response text: {response.text}")

            # Raise for status if there's an HTTP error
            # response.raise_for_status()

            return response
        except requests.exceptions.RequestException as e:
            self.logger.error(f"POST {url} failed: {str(e)}")
            raise
    
    def _get_request(self, url, headers):
        try:
            # Log request
            self.logger.info(f"GET Request URL: {url}")
            self.logger.debug(f"GET Request Headers: {headers}")

            # Create request
            response = requests.get(url, headers=headers)
            
            # Log response
            self.logger.debug(f"GET Response status_code: {response.status_code}")
            self.logger.debug(f"GET Response headers: {response.headers}")
            self.logger.debug(f"GET Response text: {response.text}")

            # Raise for status if there's an HTTP error
            # response.raise_for_status()

            return response
        except requests.exceptions.RequestException as e:
            self.logger.error(f"GET {url} failed: {str(e)}")
            raise

    def _patch_request(self, url, headers, data):
        try:
            # Log request
            self.logger.info(f"PATCH Request URL: {url}")
            self.logger.debug(f"PATCH Request Headers: {headers}")
            self.logger.debug(f"PATCH Request Data: {data}")

            # Create request
            response = requests.patch(url, headers=headers, data=data)
            
            # Log response details
            self.logger.debug(f"PATCH Response status_code: {response.status_code}")
            self.logger.debug(f"PATCH Response headers: {response.headers}")
            self.logger.debug(f"PATCH Response text: {response.text}")

            # Raise for status if there's an HTTP error
            # response.raise_for_status()

            return response
        except requests.exceptions.RequestException as e:
            self.logger.error(f"PATCH {url} failed: {str(e)}")
            raise

    # -------------------------------------------------------------
    # ---------------- POST METHODS -------------------------------
    # -------------------------------------------------------------

    def create_policy(self, policyNumber, policyType, status, productCode, inceptionDate, policyEntities):
        path = '/api/v1/policies/import'
        url = f'{self.base_url}{path}'
        payload = {
            "policyNumber": policyNumber,
            "policyType": policyType,
            "status": status,
            "productCode": productCode,
            "inceptionDate": inceptionDate,
            "policyEntities": policyEntities
        }

        payload = {k: v for k, v in payload.items() if v is not None}
        payload_json = json.dumps(payload)
        headers = self._generate_headers('POST', path, payload_json)

        result = None
        result_text = None
        success = False

        try:
            result = self._post_request(url, headers, payload_json)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to create policy {policyNumber}: {result_text}")

        return success, result_text
        
    def create_claim(self, claimNumber, claimType, status, policyNumber, datetimeOfLoss, datetimeOfNotification,
                     accountCode, lossType, claimIncidentDetails, exposures, vehicles, claimParties):
        path = '/api/v1/claims'
        url = f'{self.base_url}{path}'
        payload = {
            "claimNumber": claimNumber,
            "claimType": claimType,
            "status": status,
            "policyNumber": policyNumber,
            "datetimeOfLoss": datetimeOfLoss,
            "datetimeOfNotification": datetimeOfNotification,
            "accountCode": accountCode,
            "lossType": lossType,
            "claimIncidentDetails": claimIncidentDetails,
            "exposures": exposures,
            "vehicles": vehicles,
            "claimParties": claimParties
        }

        payload = {k: v for k, v in payload.items() if v is not None}
        payload_json = json.dumps(payload)
        headers = self._generate_headers('POST', path, payload_json)

        result = None
        result_text = None
        success = False

        try:
            result = self._post_request(url, headers, payload_json)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to create claim {claimNumber}: {result_text}")

        return success, result_text
        
    def create_note(self, data_json):
        path = '/api/v2/notes'
        url = f'{self.base_url}{path}'
        
        if isinstance(data_json, str):
            try:
                data_json = json.loads(data_json)
            except json.JSONDecodeError as e:
                self.logger.error(f"Invalid JSON format for data: {data_json}")
                return False, f"Error (JSONDecodeError): {str(e)}"

        payload = {k: v for k, v in data_json.items() if v is not None}
        payload_json = json.dumps(payload)
        headers = self._generate_headers('POST', path, payload_json)
    
        result = None
        result_text = None
        success = False

        try:
            result = self._post_request(url, headers, payload_json)
            if result.status_code == 201:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to create Note: {result_text}")

        return success, result_text
    
    def create_financial_transaction(self, data_json):
        path = '/api/v2/financial_transactions'
        url = f'{self.base_url}{path}'
        
        if isinstance(data_json, str):
            try:
                data_json = json.loads(data_json)
            except json.JSONDecodeError as e:
                self.logger.error(f"Invalid JSON format for data_json: {data_json}")
                return False, f"Error (JSONDecodeError): {str(e)}"

        payload = {k: v for k, v in data_json.items() if v is not None}
        payload_json = json.dumps(payload)
        headers = self._generate_headers('POST', path, payload_json)

        result = None
        result_text = None
        success = False

        try:
            result = self._post_request(url, headers, payload_json)
            if result.status_code == 201:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to create Financial Transaction: {result_text}")

        return success, result_text

    # -------------------------------------------------------------
    # ---------------- GET METHODS --------------------------------
    # -------------------------------------------------------------

    def fetch_a_claim(self, claim_id):
        path = f'/api/v2/claims/{claim_id}'
        url = f'{self.base_url}{path}'
        headers = self._generate_headers('GET', path)

        result = None
        result_text = None
        success = False

        try:
            result = self._get_request(url, headers)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to get claim {claim_id}: {result_text}")

        return success, result_text
    
    def fetch_an_exposure(self, exposure_id):
        path = f'/api/v2/exposures/{exposure_id}'
        url = f'{self.base_url}{path}'
        headers = self._generate_headers('GET', path)

        result = None
        result_text = None
        success = False

        try:
            result = self._get_request(url, headers)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to get exposure_id {exposure_id}: {result_text}")

        return success, result_text

    def list_exposures(self, claim_id):
        params = {'filter[claim_id_eq]': claim_id}
        query_string = urlencode(params)

        path = f'/api/v2/exposures?{query_string}'
        url = f'{self.base_url}{path}'
        headers = self._generate_headers('GET', path)

        result = None
        result_text = None
        success = False

        try:
            result = self._get_request(url, headers)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to get a list of exposures for Claim Id {claim_id}: {result_text}")

        return success, result_text
    
    # --------------------------------------------------------------
    # ---------------- PATCH METHODS -------------------------------
    # --------------------------------------------------------------
    
    def update_an_exposure(self, exposure_id, data):
        path = f'/api/v2/exposures/{exposure_id}'
        url = f'{self.base_url}{path}'
        payload_json = json.dumps(data)
        headers = self._generate_headers('PATCH', path, payload_json)
        
        result = None
        result_text = None
        success = False

        try:
            result = self._patch_request(url, headers, payload_json)
            if result.status_code == 200:
                success = True
                result_text = result.text
            else:
                result_text = f"code: {result.status_code} | reason: {result.reason} | text: {result.text}"
        except requests.exceptions.RequestException as e:
            result_text = f"Error (RequestException): {str(e)}"
            self.logger.error(f"Failed to update exposure {exposure_id}: {result_text}")

        return success, result_text

