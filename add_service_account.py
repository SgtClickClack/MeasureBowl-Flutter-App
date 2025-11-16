#!/usr/bin/env python3
"""
Script to add service account to Google Play Console using the Google Play Developer API.
"""

import json
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

def add_service_account_to_play_console():
    """Add the service account to Google Play Console with proper permissions."""
    
    # Load the service account credentials
    credentials_path = "../../fastlane/play-console-credentials.json"
    
    if not os.path.exists(credentials_path):
        print(f"Error: Credentials file not found at {credentials_path}")
        return False
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        credentials_path,
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Build the service
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    # Service account details
    service_account_email = "play-console-uploader@dojo-pool.iam.gserviceaccount.com"
    package_name = "com.dojo.measurebowl"
    
    try:
        print(f"Attempting to add service account: {service_account_email}")
        print(f"To package: {package_name}")
        
        # Note: The Google Play Developer API doesn't have a direct method to add service accounts
        # This must be done through the Google Play Console web interface
        # However, we can test if the service account has access by trying to access the app
        
        print("\nTesting service account access...")
        
        # Try to get app information to test access
        try:
            app_info = service.edits().get(packageName=package_name).execute()
            print("✅ Service account has access to the app!")
            return True
        except HttpError as e:
            if e.resp.status == 404:
                print(f"❌ App with package name '{package_name}' not found.")
                print("Please verify the package name matches what you created in Google Play Console.")
            elif e.resp.status == 403:
                print("❌ Service account doesn't have access to this app.")
                print("\nTo fix this:")
                print("1. Go to https://play.google.com/console/")
                print("2. Navigate to Setup > API access")
                print("3. Find 'Service accounts' section")
                print("4. Click 'Link service account'")
                print(f"5. Enter: {service_account_email}")
                print("6. Grant permissions:")
                print("   - ✅ Release apps to testing tracks")
                print("   - ✅ View app information and download bulk reports")
                print("7. Click 'Invite user'")
            else:
                print(f"❌ Error: {e}")
            return False
        
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

if __name__ == "__main__":
    add_service_account_to_play_console()