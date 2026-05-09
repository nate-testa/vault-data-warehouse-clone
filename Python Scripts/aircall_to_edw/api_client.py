"""
Aircall API Client

Handles authentication, pagination, rate limiting, and retries
for the Aircall List All Calls endpoint.
"""

import time
import logging
import requests
from requests.auth import HTTPBasicAuth


class AircallApiClient:
    """
    Client for the Aircall REST API using HTTP Basic Auth.
    Respects rate limits via response headers and paginates automatically.
    """

    def __init__(self, credentials, api_config, logger=None):
        self.logger = logger or logging.getLogger("AircallApiClient")
        self.api_id = credentials['api_id']
        self.api_token = credentials['api_token']
        self.auth = HTTPBasicAuth(self.api_id, self.api_token)

        self.base_url = api_config.get('base_url', 'https://api.aircall.io/v1')
        self.endpoint = api_config.get('endpoint', '/calls')
        self.rate_limit_per_minute = api_config.get('rate_limit_per_minute', 60)
        self.per_page = api_config.get('per_page', 50)
        self.max_per_page = api_config.get('max_per_page', 50)
        self.max_records_per_window = api_config.get('max_records_per_window', 10000)
        self.order = api_config.get('order', 'asc')
        self.fetch_contact = api_config.get('fetch_contact', True)
        self.fetch_short_urls = api_config.get('fetch_short_urls', True)
        self.fetch_call_timeline = api_config.get('fetch_call_timeline', True)
        self.max_retries = api_config.get('max_retries', 3)
        self.retry_backoff_seconds = api_config.get('retry_backoff_seconds', 5)

        # Ensure per_page does not exceed max
        if self.per_page > self.max_per_page:
            self.per_page = self.max_per_page

        self.session = requests.Session()
        self.session.auth = self.auth

    def _build_extra_params(self):
        """Build the fetch_* params that must be sent on every page request
        (Aircall's next_page_link does NOT preserve them)."""
        extra = {}
        if self.fetch_contact:
            extra['fetch_contact'] = 'true'
        if self.fetch_short_urls:
            extra['fetch_short_urls'] = 'true'
        if self.fetch_call_timeline:
            extra['fetch_call_timeline'] = 'true'
        return extra

    def _build_params(self, from_ts, to_ts, page=1):
        params = {
            'from': str(from_ts),
            'to': str(to_ts),
            'order': self.order,
            'per_page': self.per_page,
            'page': page,
        }
        params.update(self._build_extra_params())
        return params

    def _respect_rate_limit(self, response):
        remaining = response.headers.get('X-AircallApi-Remaining')
        reset_ts = response.headers.get('X-AircallApi-Reset')

        if remaining is not None and int(remaining) <= 1 and reset_ts is not None:
            wait_until = int(reset_ts)
            now = int(time.time())
            sleep_seconds = max(wait_until - now, 1)
            self.logger.warning(
                f"Rate limit nearly exhausted (remaining={remaining}). "
                f"Sleeping {sleep_seconds}s until reset."
            )
            time.sleep(sleep_seconds)

    def _request_with_retry(self, url, params):
        for attempt in range(1, self.max_retries + 1):
            try:
                response = self.session.get(url, params=params, timeout=30)

                if response.status_code == 200:
                    self._respect_rate_limit(response)
                    return response.json()

                if response.status_code == 429:
                    reset_ts = response.headers.get('X-AircallApi-Reset')
                    if reset_ts:
                        sleep_seconds = max(int(reset_ts) - int(time.time()), 1)
                    else:
                        sleep_seconds = self.retry_backoff_seconds * attempt
                    self.logger.warning(
                        f"Rate limited (429). Attempt {attempt}/{self.max_retries}. "
                        f"Sleeping {sleep_seconds}s."
                    )
                    time.sleep(sleep_seconds)
                    continue

                if response.status_code >= 500:
                    sleep_seconds = self.retry_backoff_seconds * attempt
                    self.logger.warning(
                        f"Server error {response.status_code}. Attempt {attempt}/{self.max_retries}. "
                        f"Sleeping {sleep_seconds}s."
                    )
                    time.sleep(sleep_seconds)
                    continue

                # 4xx (non-429) — do not retry
                self.logger.error(
                    f"API error {response.status_code}: {response.text}"
                )
                response.raise_for_status()

            except requests.exceptions.Timeout:
                sleep_seconds = self.retry_backoff_seconds * attempt
                self.logger.warning(
                    f"Request timeout. Attempt {attempt}/{self.max_retries}. "
                    f"Sleeping {sleep_seconds}s."
                )
                time.sleep(sleep_seconds)

            except requests.exceptions.ConnectionError:
                sleep_seconds = self.retry_backoff_seconds * attempt
                self.logger.warning(
                    f"Connection error. Attempt {attempt}/{self.max_retries}. "
                    f"Sleeping {sleep_seconds}s."
                )
                time.sleep(sleep_seconds)

        raise RuntimeError(
            f"Failed to fetch data after {self.max_retries} attempts."
        )

    def fetch_all_calls(self, from_ts, to_ts):
        """
        Fetch all calls for a given time window, handling pagination.

        Pagination is driven by following the 'next_page_link' URL returned
        in each response's 'meta' object — the first request uses built params,
        subsequent requests follow the link directly from the API response.

        Args:
            from_ts: UNIX timestamp (int) — start of window (inclusive).
            to_ts: UNIX timestamp (int) — end of window (inclusive).

        Returns:
            List of call dicts from the API.
        """
        all_calls = []

        # First request: build URL and params from config
        url = f"{self.base_url}{self.endpoint}"
        params = self._build_params(from_ts, to_ts, page=1)

        self.logger.info(
            f"Fetching calls from {from_ts} to {to_ts} "
            f"(per_page={self.per_page}, order={self.order})..."
        )

        # fetch_* params must be re-sent on every page because
        # Aircall's next_page_link does not preserve them.
        extra_params = self._build_extra_params()

        while True:
            if params is not None:
                data = self._request_with_retry(url, params)
            else:
                # next_page_link already has pagination params;
                # append the fetch_* params that Aircall strips.
                data = self._request_with_retry(url, params=extra_params)

            calls = data.get('calls', [])
            meta = data.get('meta', {})
            all_calls.extend(calls)

            total = meta.get('total', 0)
            current_page = meta.get('current_page', 0)
            next_page_link = meta.get('next_page_link')

            self.logger.info(
                f"Page {current_page}: fetched {len(calls)} calls "
                f"({len(all_calls)}/{total} total)"
            )

            if not next_page_link or len(calls) == 0:
                break

            # Follow the next_page_link directly from the response
            url = next_page_link
            params = None  # signal to use URL + extra_params

            # Safety check: Aircall caps pagination at max_records_per_window
            if len(all_calls) >= self.max_records_per_window:
                self.logger.warning(
                    f"Reached pagination cap ({self.max_records_per_window}). "
                    f"Use smaller time windows to retrieve all data."
                )
                break

        self.logger.info(f"Total calls fetched: {len(all_calls)}")
        return all_calls

    def test_connection(self):
        """Ping the API to verify credentials."""
        url = f"{self.base_url}/ping"
        try:
            response = self.session.get(url, timeout=15)
            if response.status_code == 200 and response.json().get('ping') == 'pong':
                self.logger.info("Aircall API connection verified (ping/pong).")
                return True
            else:
                self.logger.error(
                    f"Aircall API ping failed: {response.status_code} {response.text}"
                )
                return False
        except Exception as e:
            self.logger.error(f"Aircall API connection test failed: {e}")
            return False
