import requests
from datetime import datetime
from airflow.models import Variable

ENVIRONMENT = Variable.get("environment")

def call_honk_api():
    print('******start******')
    try:
        if ENVIRONMENT == 'PRODUCTION':
            api_url = Variable.get("honk_api_url")
            headers = {}
            response = requests.get(api_url, headers=headers, timeout=10)
            response.raise_for_status()  # Raise an HTTPError for bad status codes (4xx, 5xx)
            data = response.json()
            print(f"**response data: {data}")
        else:
            return_value = f"**Skipping Honk API call in {ENVIRONMENT} environment, it should be called only in PRODUCTION."
            print(return_value)
            data = {"message": return_value}
        
    except requests.exceptions.Timeout as e:
        print(f"**timeout reached: {e}")
        raise  # Re-raise the exception to fail the DAG task
    except requests.exceptions.HTTPError as e:
        print(f"**HTTP Error: {e}")
        raise  # Re-raise the exception to fail the DAG task
    except Exception as e:
        print(f"**Error: {e}")
        raise  # Re-raise the exception to fail the DAG task
    print('******end******')
    return data
