import requests
from datetime import datetime
from airflow.models import Variable

ENVIRONMENT = Variable.get("environment")

def call_honk_api():
    print('******start******')
    response = None
    try:
        if ENVIRONMENT == 'PRODUCTION':
            api_url = Variable.get("honk_api_url")
            headers = {}
            response = requests.get(api_url, headers=headers, timeout=10)
            response.raise_for_status()  # Raise an HTTPError for bad status codes (4xx, 5xx)
            
            print(f"**Response status code: {response.status_code}")
            print(f"**Response content type: {response.headers.get('Content-Type', 'N/A')}")
            print(f"**Response text: {response.text[:200] if response.text else 'Empty'}")
            
            # Check if response has JSON content
            if response.text.strip() and 'application/json' in response.headers.get('Content-Type', ''):
                data = response.json()
                print(f"**response data: {data}")
            else:
                # If not JSON, return success with response info
                data = {
                    "message": "API call successful", 
                    "status_code": response.status_code,
                    "content": response.text[:500] if response.text else "No content"
                }

        else:
            return_value = f"**Skipping Honk API call in {ENVIRONMENT} environment, it should be called only in PRODUCTION."
            print(return_value)
            data = {"message": return_value}
        
    except requests.exceptions.Timeout as e:
        print(f"**timeout reached: {e}")
        raise  # Re-raise the exception to fail the DAG task
    except requests.exceptions.HTTPError as e:
        print(f"**HTTP Error: {e}")
        print(f"**Response content: {e.response.text if hasattr(e, 'response') else 'N/A'}")
        raise  # Re-raise the exception to fail the DAG task
    except requests.exceptions.JSONDecodeError as e:
        print(f"**JSON Decode Error: {e}")
        if response is not None:
            print(f"**Response status code: {response.status_code}")
            print(f"**Response content: {response.text}")
        raise  # Re-raise the exception to fail the DAG task
    except Exception as e:
        print(f"**Error: {e}")
        raise  # Re-raise the exception to fail the DAG task
    print('******end******')
    return data
