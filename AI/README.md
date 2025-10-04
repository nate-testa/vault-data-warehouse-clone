## Run API:
cd /python_scripts/snowflake_ai
source .venv/bin/activate
uvicorn app.api.main:app --reload --host 0.0.0.0 --port 8080

## Run UI:
cd /python_scripts/snowflake_ai
source .venv/bin/activate
cd /python_scripts/snowflake_ai/ui
gunicorn -w 9 -b 127.0.0.1:5000 --timeout 300 app:app