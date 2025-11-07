import json
import sys
from sql_to_sql_migrator import SqlToSqlMigrator

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
    TASKS_FILE = 'sql_tasks.json' # Use the new tasks file
    
    try:
        migration_tasks = get_migration_tasks_from_json(TASKS_FILE)
        
        if migration_tasks:
            # Use the new SqlToSqlMigrator
            with SqlToSqlMigrator() as migrator:
                migrator.run_migration(migration_tasks=migration_tasks)
        else:
            print(f"No migration tasks found in {TASKS_FILE} to process.")
            sys.exit(1)

    except Exception as e:
        print(f"A critical error stopped the migration: {e}")
        sys.exit(1)