#!/usr/bin/env python3
"""
Secret Key Generator for Flask UI Applications
==============================================

This utility generates cryptographically secure SECRET_KEY values for Flask applications.
The SECRET_KEY is critical for session security, CSRF protection, and other cryptographic operations.

Usage:
    python ui/utils/secret_key_generator.py [--length 32] [--format hex|base64]
    
Examples:
    python ui/utils/secret_key_generator.py                    # Generate default 64-char hex key
    python ui/utils/secret_key_generator.py --length 64        # Generate 128-char hex key  
    python ui/utils/secret_key_generator.py --format base64    # Generate base64 encoded key

Security Best Practices:
=======================

1. WHAT IS SECRET_KEY?
   - Used by Flask to sign session cookies, CSRF tokens, and other sensitive data
   - If compromised, attackers can forge user sessions and bypass security measures
   - Must be unique per application and environment

2. GENERATION REQUIREMENTS:
   - Minimum 32 bytes (64 hex characters) for production
   - Use cryptographically secure random number generator
   - Never use predictable values, dictionary words, or personal information

3. PRODUCTION DEPLOYMENT:
   
   Step 1: Generate the key
   ------------------------
   python ui/utils/secret_key_generator.py
   
   Step 2: Set as environment variable (RECOMMENDED)
   ------------------------------------------------
   # On the production server:
   export FLASK_SECRET_KEY="your-generated-key-here"
   
   # Or add to system profile:
   echo 'export FLASK_SECRET_KEY="your-key"' >> ~/.bashrc
   source ~/.bashrc
   
   Step 3: Alternative - Add to .env file
   --------------------------------------
   # In your ui/.env file (NEVER commit to Git):
   FLASK_SECRET_KEY=your-generated-key-here
   
   # Add .env to .gitignore:
   echo "ui/.env" >> .gitignore

4. KEY ROTATION SCHEDULE:
   
   Mandatory rotation:
   - Immediately upon security breach or suspected compromise
   - When employee with access leaves the organization
   - After any security incident
   
   Recommended rotation:
   - Every 6-12 months as part of security maintenance
   - During major application updates or infrastructure changes
   
   ⚠️  WARNING: Rotating SECRET_KEY invalidates all active user sessions!
   Plan key rotation during maintenance windows and notify users.

5. DEPLOYMENT CHECKLIST:
   
   Before Production:
   □ Generate unique SECRET_KEY for production environment
   □ Store key securely (environment variable or secrets manager)  
   □ Verify key is not in source code or committed to version control
   □ Test application startup with new key
   □ Document key rotation procedures
   
   During Deployment:
   □ Set SECRET_KEY environment variable on production server
   □ Restart application to load new key
   □ Verify application functionality
   □ Monitor for session-related errors
   
   After Deployment:
   □ Securely backup the key in encrypted storage
   □ Document key generation date and rotation schedule
   □ Test user authentication and session management
   □ Remove any temporary key files

6. ENVIRONMENT-SPECIFIC KEYS:
   - Development: Can use generated or fixed key for consistency
   - Staging: Should use unique key different from production
   - Production: Must use unique, securely stored key
   - Never share keys between environments

7. SECURITY MONITORING:
   - Log FLASK_SECRET_KEY rotation events (but never log the actual key)
   - Monitor for unusual session behavior after key changes
   - Set up alerts for failed session validations
   - Regularly audit key storage and access

8. BACKUP AND RECOVERY:
   - Store backup of current FLASK_SECRET_KEY in encrypted form
   - Document key recovery procedures
   - Test key restoration process
   - Plan for emergency key rotation

9. COMMON MISTAKES TO AVOID:
   ❌ Using same key across environments
   ❌ Hardcoding keys in source code
   ❌ Committing .env files with keys to Git
   ❌ Using weak or predictable keys
   ❌ Not rotating keys after security incidents
   ❌ Forgetting to restart application after key change
   ❌ Not backing up keys before rotation

10. FOR THIS UI APPLICATION:
    
    Quick Setup for Development:
    ---------------------------
    # Generate key and add to ui/.env
    python ui/utils/secret_key_generator.py --instructions
    
    # Copy the generated key and add to ui/.env:
    FLASK_SECRET_KEY=your-generated-key-here
    
    Production Setup:
    ----------------
    # Generate production key
    python ui/utils/secret_key_generator.py --length 64
    
    # Set as environment variable on production server
    export FLASK_SECRET_KEY="your-production-key"
    
    # Verify it's loaded correctly
    python -c "import os; print('✅ Key loaded' if os.getenv('FLASK_SECRET_KEY') else '❌ Key not found')"
"""

import argparse
import secrets
import base64
import sys
import os
from datetime import datetime


def generate_secret_key(length_bytes=32, output_format='hex'):
    """
    Generate a cryptographically secure secret key.
    
    Args:
        length_bytes (int): Length of the key in bytes (default: 32 = 64 hex chars)
        output_format (str): Output format - 'hex' or 'base64'
    
    Returns:
        str: Generated secret key
    """
    # Generate random bytes
    random_bytes = secrets.token_bytes(length_bytes)
    
    if output_format.lower() == 'base64':
        return base64.urlsafe_b64encode(random_bytes).decode('ascii')
    else:  # hex format (default)
        return secrets.token_hex(length_bytes)


def validate_key_strength(key, min_length=64):
    """
    Validate the strength of a secret key.
    
    Args:
        key (str): Secret key to validate
        min_length (int): Minimum required length
    
    Returns:
        tuple: (is_valid, message)
    """
    if len(key) < min_length:
        return False, f"Key too short. Minimum {min_length} characters required."
    
    # Check for common weak patterns
    weak_patterns = ['123', 'abc', 'password', 'secret', 'key', '000', 'aaa']
    key_lower = key.lower()
    
    for pattern in weak_patterns:
        if pattern in key_lower:
            return False, f"Key contains weak pattern: {pattern}"
    
    return True, "Key meets security requirements"


def get_deployment_instructions(key, format_type):
    """
    Generate deployment instructions for the secret key.
    
    Args:
        key (str): Generated secret key
        format_type (str): Format of the key
    
    Returns:
        str: Formatted deployment instructions
    """
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    instructions = f"""
===========================================
SECRET KEY DEPLOYMENT INSTRUCTIONS
===========================================

Generated: {timestamp}
Format: {format_type.upper()}
Length: {len(key)} characters

FOR UI APPLICATION DEPLOYMENT:

1. DEVELOPMENT SETUP:
   # Add to ui/.env file:
   FLASK_SECRET_KEY={key}
   
   # Verify it loads correctly:
   cd ui && python -c "from dotenv import load_dotenv; import os; load_dotenv(); print('✅ Key loaded' if os.getenv('FLASK_SECRET_KEY') else '❌ Key not found')"

2. PRODUCTION SETUP (Environment Variable - RECOMMENDED):
   export FLASK_SECRET_KEY="{key}"
   
   # Or add to system profile:
   echo 'export FLASK_SECRET_KEY="{key}"' >> ~/.bashrc
   source ~/.bashrc

3. PRODUCTION SETUP (Alternative - .env file):
   # In ui/.env file on production server:
   FLASK_SECRET_KEY={key}
   
   # Ensure .env is not in version control:
   echo "ui/.env" >> .gitignore

4. VERIFY DEPLOYMENT:
   # Test that Flask app loads the key correctly:
   python ui/app.py --check-config
   
   # Or check manually:
   python -c "import os; print('✅ Key loaded' if os.getenv('FLASK_SECRET_KEY') else '❌ Key not found')"

5. BACKUP INFORMATION:
   Date Generated: {timestamp}
   Key: {key}
   Next Rotation Due: {datetime.now().strftime("%Y-%m-%d")} + 6-12 months
   Environment: [DEVELOPMENT/STAGING/PRODUCTION]

⚠️  SECURITY REMINDERS:
   - Store this information in a secure, encrypted location
   - Never commit .env files with FLASK_SECRET_KEY to Git
   - Rotate key every 6-12 months or after security incidents
   - Monitor application logs after key rotation

6. TESTING CHECKLIST:
   □ UI application starts without errors
   □ User sessions work correctly
   □ SSO authentication functions properly
   □ No session-related errors in logs
   
===========================================
"""
    return instructions


def check_env_file():
    """
    Check if ui/.env file exists and has FLASK_SECRET_KEY configured.
    
    Returns:
        tuple: (exists, has_secret_key, current_key_length)
    """
    ui_env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    
    if not os.path.exists(ui_env_path):
        return False, False, 0
    
    try:
        with open(ui_env_path, 'r') as f:
            content = f.read()
            for line in content.split('\n'):
                if line.strip().startswith('FLASK_SECRET_KEY='):
                    key_value = line.split('=', 1)[1].strip()
                    return True, True, len(key_value)
        return True, False, 0
    except Exception:
        return False, False, 0


def main():
    """Main function to handle command line interface."""
    parser = argparse.ArgumentParser(
        description="Generate cryptographically secure FLASK_SECRET_KEY for Flask UI applications",
        epilog="Example: python ui/utils/secret_key_generator.py --length 64 --format base64"
    )
    
    parser.add_argument(
        '--length', 
        type=int, 
        default=32,
        help='Length in bytes (default: 32 bytes = 64 hex chars)'
    )
    
    parser.add_argument(
        '--format', 
        choices=['hex', 'base64'],
        default='hex',
        help='Output format (default: hex)'
    )
    
    parser.add_argument(
        '--validate',
        type=str,
        help='Validate an existing secret key'
    )
    
    parser.add_argument(
        '--instructions',
        action='store_true',
        help='Show detailed deployment instructions'
    )
    
    parser.add_argument(
        '--check-env',
        action='store_true',
        help='Check current ui/.env file status'
    )
    
    args = parser.parse_args()
    
    # Check env file status
    if args.check_env:
        env_exists, has_key, key_length = check_env_file()
        print("🔍 UI .ENV FILE STATUS")
        print("=" * 30)
        print(f"ui/.env exists: {'✅ Yes' if env_exists else '❌ No'}")
        print(f"FLASK_SECRET_KEY configured: {'✅ Yes' if has_key else '❌ No'}")
        if has_key:
            print(f"Key length: {key_length} characters")
            is_valid, message = validate_key_strength('x' * key_length, 64)
            print(f"Key strength: {'✅ Strong' if is_valid else '⚠️ Weak'}")
        return
    
    # Validate existing key if provided
    if args.validate:
        is_valid, message = validate_key_strength(args.validate)
        if is_valid:
            print(f"✅ {message}")
            print(f"Key length: {len(args.validate)} characters")
        else:
            print(f"❌ {message}")
            print(f"Key length: {len(args.validate)} characters")
        return
    
    # Generate new key
    try:
        secret_key = generate_secret_key(args.length, args.format)
        
        # Validate generated key
        is_valid, validation_message = validate_key_strength(secret_key)
        
        if not is_valid:
            print(f"❌ Generated key validation failed: {validation_message}")
            sys.exit(1)
        
        print("🔐 SECURE FLASK_SECRET_KEY GENERATED FOR UI")
        print("=" * 50)
        print(f"FLASK_SECRET_KEY={secret_key}")
        print("=" * 50)
        print(f"✅ Format: {args.format.upper()}")
        print(f"✅ Length: {len(secret_key)} characters")
        print(f"✅ Strength: {validation_message}")
        
        # Check current env status
        env_exists, has_key, current_length = check_env_file()
        if env_exists:
            if has_key:
                print(f"ℹ️  Current ui/.env has FLASK_SECRET_KEY ({current_length} chars)")
            else:
                print("ℹ️  ui/.env exists but no FLASK_SECRET_KEY found")
        else:
            print("ℹ️  ui/.env file does not exist")
        
        if args.instructions:
            print(get_deployment_instructions(secret_key, args.format))
        else:
            print("\nQUICK SETUP:")
            print(f"Add this line to ui/.env: FLASK_SECRET_KEY={secret_key}")
            print("\nFor detailed instructions, run with --instructions flag")
        
    except Exception as e:
        print(f"❌ Error generating secret key: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
