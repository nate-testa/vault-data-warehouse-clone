import requests
import hashlib
import hmac
import base64
import json
import logging
import time
from datetime import datetime
from urllib.parse import urlencode


# Parameters
P_SECRET = 'CJNWgmHUMiQnpRFJoZvb'
P_KEY = 'vault_us_api'
P_BASE_URL = 'https://test.snapsheetvice.com'

class SnapsheetAPI:
    # Class-level variables to maintain shared state across instances
    request_count = 0               # For enforcing rate limit
    start_time = time.time()        # Initialize start time as class-level attribute
    global_start_time = time.time() # For calculating global execution time
    total_requests_sent = 0         # For tracking the total number of requests sent

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

    # Rate limiting function
    @classmethod
    def enforce_rate_limit(cls, max_requests=90, time_window=10):
        # Check if the request count exceeds the allowed max_requests
        if cls.request_count >= max_requests:
            elapsed_time = time.time() - cls.start_time
            if elapsed_time < time_window:
                # Pause execution until the time window resets
                time.sleep(time_window - elapsed_time)

            # Reset the request count and start time after the wait
            cls.request_count = 0
            cls.start_time = time.time()

    def _post_request(self, url, headers, data, max_retries=5):
        try:
            # Use the global start time for calculating total execution time across all requests
            SnapsheetAPI.global_start_time = SnapsheetAPI.global_start_time or time.time()

            # Enforce rate limit before making the request
            if "/claims" in url and "/v1/" in url:
                self.enforce_rate_limit(9, 10)  # Limit to 9 requests every 10 seconds
            else:
                self.enforce_rate_limit(90, 10)  # Default limit to 90 requests every 10 seconds

            retry_count = 0
            while retry_count < max_retries:
                # Log request
                self.logger.info(f"POST Request URL: {url}")
                self.logger.debug(f"POST Request Headers: {headers}")
                self.logger.debug(f"POST Request Data: {data}")

                # Create request
                response = requests.post(url, headers=headers, data=data)
                SnapsheetAPI.request_count += 1  # Increment class-level request count
                SnapsheetAPI.total_requests_sent += 1  # Increment global total requests sent (for tracking only)

                # If response is successful or not a 429 error, return the response
                if response.status_code != 429:
                    # Log response
                    self.logger.debug(f"POST Response status_code: {response.status_code}")
                    self.logger.debug(f"POST Response headers: {response.headers}")
                    self.logger.debug(f"POST Response text: {response.text}")

                    # Calculate and log total execution time and total requests sent
                    total_end_time = time.time()
                    total_execution_time = total_end_time - SnapsheetAPI.global_start_time
                    self.logger.info(f"Total execution time for all POST requests: {total_execution_time:.2f} seconds")
                    self.logger.info(f"Total requests sent for all POST operations: {SnapsheetAPI.total_requests_sent}")

                    return response

                # If response is 429, log the Retry-After value if present
                retry_count += 1
                retry_after = response.headers.get('Retry-After')
                if retry_after:
                    self.logger.warning(f"Received 429 Too Many Requests. Retry-After: {retry_after} seconds")
                    wait_time = int(retry_after)  # Use Retry-After header if present
                else:
                    wait_time = 2 ** retry_count  # Exponential backoff: 2, 4, 8, etc. seconds

                # Log the chosen wait time
                self.logger.warning(f"Retrying in {wait_time} seconds...")
                time.sleep(wait_time)

            # If max retries exceeded, raise an exception
            raise Exception(f"Max retries exceeded for POST request to {url}")

        except requests.exceptions.RequestException as e:
            # Log total execution time and requests sent in case of an exception
            total_end_time = time.time()
            total_execution_time = total_end_time - SnapsheetAPI.global_start_time
            self.logger.error(f"POST {url} failed after {total_execution_time:.2f} seconds with {SnapsheetAPI.total_requests_sent} requests: {str(e)}")
            raise

    def _get_request(self, url, headers):
        try:
            # Enforce rate limit before making the request
            self.enforce_rate_limit()

            # Log request
            self.logger.info(f"GET Request URL: {url}")
            self.logger.debug(f"GET Request Headers: {headers}")

            # Create request
            response = requests.get(url, headers=headers)
            self.request_count += 1  # Increment request count after each call

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
            # Enforce rate limit before making the request
            self.enforce_rate_limit()

            # Log request
            self.logger.info(f"PATCH Request URL: {url}")
            self.logger.debug(f"PATCH Request Headers: {headers}")
            self.logger.debug(f"PATCH Request Data: {data}")

            # Create request
            response = requests.patch(url, headers=headers, data=data)
            self.request_count += 1  # Increment request count after each call

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
        
    def create_claim(self, claimNumber, claimType, status, policyNumber, firstOpenedAt, firstClosedAt, openedAt, closedAt, datetimeOfLoss, datetimeOfNotification, fraudScore, fraudLevelIndicator, providerCode, coverageCheck,
         accountCode, lossType, notes, reservation, claimIncidentDetails, emergencyServicesDetail, notifier, notificationMethod, exposures, claimParties, vehicles, financialTransactions):
        path = '/api/v1/claims'
        url = f'{self.base_url}{path}'
        payload = {
            "claimNumber": claimNumber,
            "claimType": claimType,
            "status": status,
            "policyNumber": policyNumber,
            "firstOpenedAt": firstOpenedAt,
            "firstClosedAt": firstClosedAt,
            "openedAt": openedAt,
            "closedAt": closedAt,
            "datetimeOfLoss": datetimeOfLoss,
            "datetimeOfNotification": datetimeOfNotification,
            "fraudScore": fraudScore,
            "fraudLevelIndicator": fraudLevelIndicator,
            "providerCode": providerCode,
            "coverageCheck": coverageCheck,
            "accountCode": accountCode,
            "lossType": lossType,
            "notes": notes,
            "reservation": reservation,
            "claimIncidentDetails": claimIncidentDetails,
            "emergencyServicesDetail": emergencyServicesDetail,
            "notifier": notifier,
            "notificationMethod": notificationMethod,
            "exposures": exposures,
            "claimParties": claimParties,
            "vehicles": vehicles,
            "financialTransactions": financialTransactions
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

