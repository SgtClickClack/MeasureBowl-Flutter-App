#!/usr/bin/env python3
import json
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

def list_available_apps():
    """Try to list available apps using the service account."""
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        "../../fastlane/measurebowl-credentials.json",
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Build the service
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    print("Service account:", credentials.service_account_email)
    print("Testing different approaches to find apps...")
    
    # Try different methods to find apps
    methods = [
        ("edits().list()", lambda pkg: service.edits().list(packageName=pkg).execute()),
        ("edits().insert()", lambda pkg: service.edits().insert(body={}, packageName=pkg).execute()),
        ("reviews().list()", lambda pkg: service.reviews().list(packageName=pkg).execute()),
    ]
    
    # Try common package name patterns
    package_patterns = [
        "com.example.measurebowl",
        "com.dojo.measurebowl", 
        "com.measurebowl.app",
        "com.measurebowl",
        "com.lawnbowls.measurebowl",
        "com.julian.measurebowl",
        "com.gilbertroberts.measurebowl",
        "com.kickybreaks.measurebowl"
    ]
    
    found_packages = []
    
    for package_name in package_patterns:
        print(f"\nTesting package: {package_name}")
        
        for method_name, method_func in methods:
            try:
                result = method_func(package_name)
                print(f"  ✅ {method_name} succeeded!")
                print(f"  Result: {json.dumps(result, indent=2)[:200]}...")
                found_packages.append(package_name)
                break
            except HttpError as e:
                if e.resp.status == 404:
                    print(f"  ❌ {method_name}: Package not found")
                else:
                    print(f"  ⚠️  {method_name}: {e}")
            except Exception as e:
                print(f"  ⚠️  {method_name}: {e}")
    
    if found_packages:
        print(f"\n🎉 Found accessible packages: {found_packages}")
        return found_packages[0]  # Return the first one found
    else:
        print("\n❌ No accessible packages found")
        return None

if __name__ == "__main__":
    result = list_available_apps()
    if result:
        print(f"\n✅ Use this package name: {result}")
    else:
        print("\n❌ Could not find any accessible packages")
