import requests
from datetime import datetime
from airflow.models import Variable

def call_honk_api():
    print('******start******')
    try:
        api_url = Variable.get("honk_api_url")

        headers = {}

        response = requests.get(api_url, headers=headers, timeout=10)
        data = response.json()
        print(f"**response data: {data}")
    except requests.exceptions.Timeout:
        print("**timeout reached")
        data = None
    except Exception as e:
        print(f"**Error: {e}")
        data = None
    print('******end******')
    return data
