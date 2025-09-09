#!/usr/bin/env python3
"""
Test script for CSV upload functionality
"""

import requests
import os

def test_csv_upload():
    """Test the CSV upload endpoint"""
    
    # Base URL
    base_url = "http://localhost:5000"
    
    # Check if backend is running
    try:
        health_response = requests.get(f"{base_url}/health")
        if health_response.status_code == 200:
            print("✓ Backend is running")
        else:
            print("✗ Backend health check failed")
            return
    except requests.exceptions.ConnectionError:
        print("✗ Backend is not running. Please start it with: python app.py")
        return
    
    # Test CSV upload
    csv_file_path = "sample_namaste_codes.csv"
    
    if not os.path.exists(csv_file_path):
        print(f"✗ CSV file not found: {csv_file_path}")
        return
    
    print(f"\nUploading {csv_file_path}...")
    
    # Use the simple endpoint that doesn't require authentication
    url = f"{base_url}/ingest/csv-simple"
    
    try:
        with open(csv_file_path, 'rb') as f:
            files = {'file': (csv_file_path, f, 'text/csv')}
            response = requests.post(url, files=files)
        
        print(f"Response Status: {response.status_code}")
        
        if response.status_code == 201:
            print("✓ CSV uploaded successfully!")
            data = response.json()
            
            # Check for outcome in response
            if 'outcome' in data:
                outcome = data['outcome']
                if outcome.get('resourceType') == 'OperationOutcome':
                    for issue in outcome.get('issue', []):
                        print(f"  {issue['severity']}: {issue['details']['text']}")
            
            # Check the codesystem
            if data.get('resourceType') == 'CodeSystem':
                print(f"\nCodeSystem created:")
                print(f"  ID: {data.get('id')}")
                print(f"  Name: {data.get('name')}")
                print(f"  URL: {data.get('url')}")
                print(f"  Count: {data.get('count', 0)} codes")
        else:
            print(f"✗ Upload failed with status {response.status_code}")
            try:
                error_data = response.json()
                if error_data.get('resourceType') == 'OperationOutcome':
                    for issue in error_data.get('issue', []):
                        print(f"  Error: {issue['details']['text']}")
                else:
                    print(f"  Response: {error_data}")
            except:
                print(f"  Response: {response.text}")
                
    except Exception as e:
        print(f"✗ Error during upload: {e}")
        import traceback
        traceback.print_exc()

def test_search():
    """Test the search functionality after upload"""
    base_url = "http://localhost:5000"
    
    print("\nTesting search functionality...")
    
    search_terms = ["vata", "diabetes", "yoga"]
    
    for term in search_terms:
        url = f"{base_url}/valueset/search?q={term}&limit=5"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json()
                if data.get('resourceType') == 'ValueSet':
                    total = data.get('expansion', {}).get('total', 0)
                    print(f"✓ Search for '{term}': Found {total} results")
                    
                    # Show first few results
                    contains = data.get('expansion', {}).get('contains', [])[:3]
                    for item in contains:
                        print(f"    - {item['code']}: {item['display']}")
            else:
                print(f"✗ Search for '{term}' failed with status {response.status_code}")
        except Exception as e:
            print(f"✗ Search error: {e}")

if __name__ == "__main__":
    print("MEDISYNC CSV Upload Test")
    print("=" * 50)
    
    test_csv_upload()
    test_search()
    
    print("\n" + "=" * 50)
    print("Test complete!")
    print("\nYou can now:")
    print("1. Access the frontend at http://localhost:3000")
    print("2. Use the CSV Upload feature in the UI")
    print("3. Search for uploaded codes")
