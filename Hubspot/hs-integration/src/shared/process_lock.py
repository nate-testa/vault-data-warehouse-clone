import os
import time
from shared.logger import get_logger

logger = get_logger(__name__)

class ProcessLock:
    """
    Implements a file-based lock to prevent multiple instances of the process from running simultaneously.
    """
    
    def __init__(self, lock_file_path=None):
        """
        Initialize the ProcessLock.
        
        Args:
            lock_file_path: Path to the lock file. If None, uses current working directory.
        """
        if lock_file_path is None:
            self.lock_file_path = os.path.join(os.getcwd(), '.process.lock')
        else:
            self.lock_file_path = lock_file_path
        
        self.locked = False
    
    def acquire(self):
        """
        Attempt to acquire the lock.
        
        Returns:
            True if lock acquired successfully, False if another process is running
        """
        # Check if lock file exists
        if os.path.exists(self.lock_file_path):
            # Another process is running - get info about it
            try:
                with open(self.lock_file_path, 'r') as f:
                    lines = f.readlines()
                    pid = lines[0].strip() if len(lines) > 0 else 'unknown'
                    lock_time = float(lines[1].strip()) if len(lines) > 1 else None
                
                if lock_time:
                    running_duration = time.time() - lock_time
                    hours = int(running_duration // 3600)
                    minutes = int((running_duration % 3600) // 60)
                    
                    logger.warning(
                        f"Process is already running (PID: {pid}). "
                        f"Running for: {hours}h {minutes}m"
                    )
                    logger.warning(
                        f"Lock file: {self.lock_file_path}. "
                        f"If this is an error, manually delete the lock file."
                    )
                else:
                    logger.warning(f"Process is already running. Lock file exists: {self.lock_file_path}")
                    
            except Exception as e:
                logger.warning(f"Process is already running but could not read lock details: {e}")
            
            return False
        
        # Create lock file
        try:
            with open(self.lock_file_path, 'w') as f:
                f.write(f"{os.getpid()}\n")
                f.write(f"{time.time()}\n")
            
            self.locked = True
            logger.info(f"Process lock acquired: {self.lock_file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create lock file: {e}")
            return False
    
    def release(self):
        """
        Release the lock by removing the lock file.
        """
        if self.locked and os.path.exists(self.lock_file_path):
            try:
                os.remove(self.lock_file_path)
                self.locked = False
                logger.info(f"Process lock released: {self.lock_file_path}")
            except Exception as e:
                logger.error(f"Failed to remove lock file: {e}")
    
    def __enter__(self):
        """
        Context manager entry - acquire the lock.
        """
        if not self.acquire():
            raise RuntimeError("Could not acquire process lock - another instance may be running")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context manager exit - release the lock.
        """
        self.release()
        return False
