import requests
from datetime import datetime
from airflow.models import Variable

def call_ivans_api():
    print('******start******')
    try:
        api_url = Variable.get("ivans_api_url")

        start_date = datetime.now().strftime('%Y-%m-%d')
        end_date = datetime.now().strftime('%Y-%m-%d') 

        print(f"**parameters -> start_date: {start_date}, end_date: {end_date}")

        headers = {
            'startDate': start_date,
            'endDate': end_date
        }

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
