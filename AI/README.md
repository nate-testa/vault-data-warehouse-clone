## Run API:

cd /python_scripts/snowflake_ai
uvicorn app.api.main:app --reload --host 0.0.0.0 --port 8080

## Run UI:

cd /python_scripts/snowflake_ai/ui
sudo /home/produbuntuvmadmin/python_scripts/snowflake_ai/.venv/bin/streamlit run Home.py --server.port 80