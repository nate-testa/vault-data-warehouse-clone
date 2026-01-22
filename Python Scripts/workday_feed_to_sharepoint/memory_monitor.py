"""
Memory monitoring utilities for low-memory environments
"""
import psutil
import os
import gc
from functools import wraps


def get_memory_usage_mb():
    """Get current process memory usage in MB"""
    try:
        process = psutil.Process()
        return process.memory_info().rss / 1024 / 1024
    except Exception:
        return None


def get_system_memory_info():
    """Get system-wide memory information"""
    try:
        mem = psutil.virtual_memory()
        return {
            'total_mb': mem.total / 1024 / 1024,
            'available_mb': mem.available / 1024 / 1024,
            'used_mb': mem.used / 1024 / 1024,
            'percent': mem.percent
        }
    except Exception:
        return None


def log_memory_stats(logger, context=""):
    """Log detailed memory statistics"""
    process_mem = get_memory_usage_mb()
    system_mem = get_system_memory_info()
    
    if process_mem:
        logger.info(f"[Memory {context}] Process: {process_mem:.2f} MB")
    
    if system_mem:
        logger.info(f"[Memory {context}] System: {system_mem['used_mb']:.0f}MB / "
                   f"{system_mem['total_mb']:.0f}MB ({system_mem['percent']:.1f}% used)")


def memory_profiler(logger=None):
    """Decorator to profile memory usage of a function"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            gc.collect()  # Force garbage collection before measuring
            mem_before = get_memory_usage_mb()
            
            result = func(*args, **kwargs)
            
            gc.collect()  # Force garbage collection after execution
            mem_after = get_memory_usage_mb()
            
            if logger and mem_before and mem_after:
                delta = mem_after - mem_before
                logger.debug(f"[Memory Profile] {func.__name__}: "
                           f"before={mem_before:.2f}MB, after={mem_after:.2f}MB, "
                           f"delta={delta:+.2f}MB")
            
            return result
        return wrapper
    return decorator


def force_garbage_collection(logger=None):
    """Force garbage collection and log results"""
    if logger:
        mem_before = get_memory_usage_mb()
    
    collected = gc.collect()
    
    if logger:
        mem_after = get_memory_usage_mb()
        if mem_before and mem_after:
            freed = mem_before - mem_after
            logger.debug(f"[GC] Collected {collected} objects, freed {freed:.2f}MB")
    
    return collected


def check_memory_threshold(threshold_mb=512, logger=None):
    """Check if memory usage exceeds threshold"""
    mem_usage = get_memory_usage_mb()
    if mem_usage and mem_usage > threshold_mb:
        if logger:
            logger.warning(f"Memory usage ({mem_usage:.2f}MB) exceeds threshold ({threshold_mb}MB)")
        return True
    return False
