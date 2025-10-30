import json
import sys
from data_migrator import DataMigrator

def get_migration_tasks_from_json(filepath: str) -> list:
    """Reads a list of migration tasks from a JSON file."""
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        return data.get("migrations", [])
    except json.JSONDecodeError as e:
        print(f"Error: Could not decode JSON from '{filepath}'. Please check the file format.")
        print(f"JSON Error details: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: The tasks file was not found at '{filepath}'")
        sys.exit(1)

if __name__ == "__main__":
    TASKS_FILE = 'tables.json'
    
    # Migration configuration (no longer using config.yml for secrets)
    migration_config = {
        'load_all': True,  # Set to False to limit records
        'record_limit': 10000  # Only used if load_all is False
    }

    try:
        migration_tasks = get_migration_tasks_from_json(TASKS_FILE)
        
        if migration_tasks:
            # DataMigrator now loads all secrets from Azure Key Vault automatically
            with DataMigrator(migration_config=migration_config) as migrator:
                migrator.run_migration(migration_tasks=migration_tasks)
        else:
            print("No migration tasks found in the JSON file to process.")
            sys.exit(1)

    except Exception as e:
        print(f"A critical error stopped the migration: {e}")
        sys.exit(1)
