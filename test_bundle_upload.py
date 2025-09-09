#!/usr/bin/env python3
"""
Test script for FHIR Bundle upload endpoint
"""

import requests
import json
from datetime import datetime

# Base URL for the API
BASE_URL = "http://localhost:5000"

def create_test_bundle():
    """Create a test FHIR Bundle with dual-coded conditions"""
    return {
        "resourceType": "Bundle",
        "type": "collection",
        "entry": [
            {
                "fullUrl": f"urn:uuid:condition-{datetime.now().timestamp()}",
                "resource": {
                    "resourceType": "Condition",
                    "id": f"condition-{int(datetime.now().timestamp())}",
                    "subject": {
                        "reference": "Patient/example",
                        "display": "Example Patient"
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "http://terminology.india.gov.in/namaste",
                                "code": "NAM001",
                                "display": "Sample NAMASTE Code"
                            },
                            {
                                "system": "http://id.who.int/icd11/mms",
                                "code": "1A00",
                                "display": "Cholera"
                            }
                        ],
                        "text": "Dual-coded condition: Cholera"
                    },
                    "clinicalStatus": {
                        "coding": [{
                            "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                            "code": "active"
                        }]
                    },
                    "verificationStatus": {
                        "coding": [{
                            "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                            "code": "confirmed"
                        }]
                    },
                    "onsetDateTime": datetime.now().isoformat()
                }
            },
            {
                "fullUrl": f"urn:uuid:condition-{datetime.now().timestamp()+1}",
                "resource": {
                    "resourceType": "Condition",
                    "id": f"condition-{int(datetime.now().timestamp())+1}",
                    "subject": {
                        "reference": "Patient/example",
                        "display": "Example Patient"
                    },
                    "code": {
                        "coding": [
                            {
                                "system": "http://terminology.india.gov.in/namaste",
                                "code": "NAM002",
                                "display": "Another NAMASTE Code"
                            },
                            {
                                "system": "http://id.who.int/icd11/mms",
                                "code": "1A10",
                                "display": "Typhoid fever"
                            }
                        ],
                        "text": "Dual-coded condition: Typhoid fever"
                    },
                    "clinicalStatus": {
                        "coding": [{
                            "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                            "code": "active"
                        }]
                    },
                    "verificationStatus": {
                        "coding": [{
                            "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                            "code": "confirmed"
                        }]
                    },
                    "onsetDateTime": datetime.now().isoformat()
                }
            }
        ]
    }

def test_bundle_upload():
    """Test the bundle upload endpoint"""
    print("Testing FHIR Bundle Upload...")
    print("-" * 50)
    
    # Create test bundle
    bundle = create_test_bundle()
    print(f"Created test bundle with {len(bundle['entry'])} entries")
    
    # Upload bundle
    url = f"{BASE_URL}/bundle/upload"
    headers = {
        "Content-Type": "application/fhir+json",
        "Accept": "application/fhir+json"
    }
    
    try:
        print(f"\nUploading bundle to {url}...")
        response = requests.post(url, json=bundle, headers=headers)
        
        print(f"Response Status: {response.status_code}")
        
        if response.status_code == 200 or response.status_code == 201:
            print("✓ Bundle uploaded successfully!")
            result = response.json()
            print(f"\nResponse Type: {result.get('resourceType', 'Unknown')}")
            
            if result.get('resourceType') == 'Bundle':
                print(f"Bundle Type: {result.get('type', 'Unknown')}")
                if 'entry' in result:
                    print(f"Processed Entries: {len(result['entry'])}")
                    for i, entry in enumerate(result['entry'], 1):
                        if 'response' in entry:
                            print(f"  Entry {i}: {entry['response'].get('status', 'Unknown status')}")
            elif result.get('resourceType') == 'OperationOutcome':
                print("Operation Outcome received:")
                for issue in result.get('issue', []):
                    print(f"  {issue['severity']}: {issue.get('diagnostics', issue.get('details', {}).get('text', 'No details'))}")
        else:
            print(f"✗ Upload failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to the backend. Is it running?")
    except Exception as e:
        print(f"✗ Error: {e}")
    
    print("-" * 50)

def test_health_check():
    """Test if the backend is running"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✓ Backend is running and healthy")
            return True
        else:
            print(f"✗ Backend returned status {response.status_code}")
            return False
    except:
        print("✗ Backend is not reachable at", BASE_URL)
        return False

if __name__ == "__main__":
    print("MEDISYNC Bundle Upload Test")
    print("=" * 50)
    
    if test_health_check():
        print()
        test_bundle_upload()
    else:
        print("\nPlease start the backend first:")
        print("  cd medisync-backend")
        print("  python app.py")
