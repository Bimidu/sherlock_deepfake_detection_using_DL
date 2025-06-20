#!/usr/bin/env python3
import requests
import sys

def test_connection():
    urls = [
        'http://localhost:8000/api/v1/health',
        'http://127.0.0.1:8000/api/v1/health',
        'http://192.168.1.61:8000/api/v1/health'
    ]
    
    for url in urls:
        try:
            print(f"Testing: {url}")
            response = requests.get(url, timeout=5)
            print(f"SUCCESS: {response.status_code} - {response.text}")
            return True
        except Exception as e:
            print(f"FAILED: {e}")
    
    return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)
