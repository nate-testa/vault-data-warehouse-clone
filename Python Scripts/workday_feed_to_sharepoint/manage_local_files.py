#!/usr/bin/env python3
"""
Utility script to manage local CSV files
Use this to check, retry uploads, or clean up files
"""

import os
import sys
import argparse
from datetime import datetime
from pathlib import Path


def list_files(directory='files'):
    """List all CSV files in the local directory"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    files_dir = os.path.join(script_dir, directory)
    
    if not os.path.exists(files_dir):
        print(f"Directory does not exist: {files_dir}")
        return []
    
    csv_files = sorted([f for f in os.listdir(files_dir) if f.endswith('.csv')])
    
    if not csv_files:
        print(f"No CSV files found in: {files_dir}")
        return []
    
    print(f"\nFound {len(csv_files)} CSV file(s) in: {files_dir}\n")
    print(f"{'Filename':<50} {'Size (MB)':<12} {'Modified':<20}")
    print("-" * 85)
    
    total_size = 0
    for filename in csv_files:
        filepath = os.path.join(files_dir, filename)
        size_mb = os.path.getsize(filepath) / 1024 / 1024
        modified = datetime.fromtimestamp(os.path.getmtime(filepath))
        total_size += size_mb
        
        print(f"{filename:<50} {size_mb:>10.2f} MB {modified.strftime('%Y-%m-%d %H:%M:%S')}")
    
    print("-" * 85)
    print(f"Total: {len(csv_files)} files, {total_size:.2f} MB\n")
    
    return csv_files


def clean_files(directory='files', confirm=True):
    """Delete all CSV files in the local directory"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    files_dir = os.path.join(script_dir, directory)
    
    if not os.path.exists(files_dir):
        print(f"Directory does not exist: {files_dir}")
        return
    
    csv_files = [f for f in os.listdir(files_dir) if f.endswith('.csv')]
    
    if not csv_files:
        print(f"No CSV files to clean in: {files_dir}")
        return
    
    print(f"\nFound {len(csv_files)} file(s) to delete:")
    for f in csv_files:
        print(f"  - {f}")
    
    if confirm:
        response = input(f"\nDelete all {len(csv_files)} file(s)? (yes/no): ")
        if response.lower() not in ['yes', 'y']:
            print("Operation cancelled.")
            return
    
    deleted = 0
    for filename in csv_files:
        filepath = os.path.join(files_dir, filename)
        try:
            os.remove(filepath)
            deleted += 1
            print(f"  ✓ Deleted: {filename}")
        except Exception as e:
            print(f"  ✗ Failed to delete {filename}: {e}")
    
    print(f"\nDeleted {deleted} of {len(csv_files)} file(s)")


def check_disk_space(directory='files'):
    """Check available disk space"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    files_dir = os.path.join(script_dir, directory)
    
    # Get disk usage
    stat = os.statvfs(files_dir if os.path.exists(files_dir) else script_dir)
    
    free_gb = (stat.f_bavail * stat.f_frsize) / (1024**3)
    total_gb = (stat.f_blocks * stat.f_frsize) / (1024**3)
    used_gb = total_gb - free_gb
    percent_used = (used_gb / total_gb) * 100
    
    print(f"\nDisk Space:")
    print(f"  Total: {total_gb:.2f} GB")
    print(f"  Used:  {used_gb:.2f} GB ({percent_used:.1f}%)")
    print(f"  Free:  {free_gb:.2f} GB")
    
    if free_gb < 1:
        print(f"\n  ⚠️  WARNING: Less than 1 GB free!")
    elif free_gb < 5:
        print(f"\n  ⚠️  Low disk space: {free_gb:.2f} GB remaining")
    else:
        print(f"\n  ✓ Sufficient disk space available")


def main():
    parser = argparse.ArgumentParser(description='Manage local CSV files')
    parser.add_argument('action', choices=['list', 'clean', 'disk'], 
                       help='Action to perform: list files, clean files, or check disk space')
    parser.add_argument('--dir', default='files', 
                       help='Directory name (default: files)')
    parser.add_argument('--force', action='store_true',
                       help='Skip confirmation for clean action')
    
    args = parser.parse_args()
    
    if args.action == 'list':
        list_files(args.dir)
    elif args.action == 'clean':
        clean_files(args.dir, confirm=not args.force)
    elif args.action == 'disk':
        check_disk_space(args.dir)
        list_files(args.dir)


if __name__ == '__main__':
    main()
