#!/usr/bin/env python3
import json
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

def test_package_variations():
    """Test common package name variations."""
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        "../../fastlane/measurebowl-credentials.json",
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Build the service
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    # Common package name variations to try
    package_variations = [
        "com.measurebowl.app",
        "com.measurebowl",
        "com.dojo.measurebowl",
        "com.julian.measurebowl",
        "com.gilbertroberts.measurebowl",
        "com.kickybreaks.measurebowl",
        "com.dojo.lawnbowls",
        "com.measurebowl.lawnbowls",
        "com.lawnbowls.measurebowl"
    ]
    
    print("Testing common package name variations...")
    
    for package_name in package_variations:
        try:
            edit = service.edits().insert(body={}, packageName=package_name).execute()
            print(f"✅ FOUND: Package {package_name} exists!")
            print(f"Edit ID: {edit['id']}")
            return package_name
        except HttpError as e:
            if e.resp.status == 404:
                print(f"❌ Package {package_name} not found")
            else:
                print(f"⚠️  Error testing {package_name}: {e}")
        except Exception as e:
            print(f"⚠️  Error testing {package_name}: {e}")
    
    print("\n❌ None of the common variations were found.")
    print("You'll need to check the exact package name in Google Play Console.")
    return None

if __name__ == "__main__":
    result = test_package_variations()
    if result:
        print(f"\n🎉 SUCCESS! Use package name: {result}")
        print("Update the Fastfile with this package name.")