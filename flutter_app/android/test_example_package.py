#!/usr/bin/env python3
import json
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

def test_example_package():
    """Test if the service account can access com.example.measurebowl."""
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        "../../fastlane/measurebowl-credentials.json",
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Build the service
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    # Test package access
    package_name = "com.example.measurebowl"
    print(f"Testing access to package: {package_name}")
    
    try:
        # Try to create an edit (this will fail if package doesn't exist)
        edit = service.edits().insert(body={}, packageName=package_name).execute()
        print(f"SUCCESS: Package {package_name} exists!")
        print(f"Edit ID: {edit['id']}")
        return True
    except HttpError as e:
        if e.resp.status == 404:
            print(f"ERROR: Package {package_name} not found")
            print("This means either:")
            print("1. The app wasn't created with this package name")
            print("2. The service account doesn't have access to this app")
            return False
        else:
            print(f"ERROR: {e}")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    test_example_package()
