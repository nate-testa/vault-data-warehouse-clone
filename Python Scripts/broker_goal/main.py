"""
Broker Goal Loader - Main Entry Point

This script loads broker goal data from Azure Blob Storage Excel files
into the vault_edw.edw_stage.stage_broker_goal SQL Server table.
"""

import sys
from broker_goal_loader import BrokerGoalLoader

if __name__ == "__main__":
    try:
        # Use the BrokerGoalLoader with context manager
        with BrokerGoalLoader() as loader:
            loader.run()
        
        print("Broker goal load completed successfully!")
        sys.exit(0)
        
    except Exception as e:
        print(f"A critical error stopped the broker goal load process: {e}")
        sys.exit(1)
