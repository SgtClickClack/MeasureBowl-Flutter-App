#!/usr/bin/env python3
import json
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

def publish_existing_release():
    """Try to publish an existing release using different package names."""
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        "../../fastlane/measurebowl-credentials.json",
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Build the service
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    # Try different package names
    package_names = [
        "com.example.measurebowl",
        "com.dojo.measurebowl", 
        "com.measurebowl.app",
        "com.measurebowl",
        "com.lawnbowls.measurebowl"
    ]
    
    for package_name in package_names:
        print(f"\nTrying package: {package_name}")
        try:
            # Try to get existing edits
            edits_response = service.edits().list(packageName=package_name).execute()
            
            if 'edits' in edits_response and edits_response['edits']:
                print(f"Found existing edits for {package_name}")
                
                # Get the latest edit
                latest_edit = edits_response['edits'][0]
                edit_id = latest_edit['id']
                print(f"Latest edit ID: {edit_id}")
                
                # Try to commit the edit (this publishes it)
                commit_response = service.edits().commit(
                    editId=edit_id,
                    packageName=package_name
                ).execute()
                
                print(f"✅ SUCCESS! Published release for {package_name}")
                print(f"Commit response: {commit_response}")
                return True
                
            else:
                print(f"No existing edits found for {package_name}")
                
        except HttpError as e:
            if e.resp.status == 404:
                print(f"Package {package_name} not found")
            else:
                print(f"Error with {package_name}: {e}")
        except Exception as e:
            print(f"Error with {package_name}: {e}")
    
    print("\n❌ No existing releases found to publish")
    return False

if __name__ == "__main__":
    publish_existing_release()
