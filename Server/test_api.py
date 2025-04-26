import requests
import json
import pandas as pd
import random
import time

API_URL = "http://localhost:5001"

def test_health():
    """Test the health endpoint"""
    response = requests.get(f"{API_URL}/health")
    print(f"Health Check Response: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    return response.status_code == 200

def generate_test_data(num_samples=5):
    """Generate some test data samples"""
    samples = []
    for _ in range(num_samples):
        sample = {
            "dayOfWeek": random.randint(0, 6),
            "hourOfDay": random.randint(0, 23),
            "minuteOfHour": random.randint(0, 59),
            "device_activity": round(random.random(), 2),
            "device_batteryLevel": round(random.uniform(0.1, 1.0), 2)
        }
        samples.append(sample)
    return samples

def test_prediction_endpoint():
    """Test the prediction endpoint with generated data"""
    test_data = generate_test_data()
    
    print(f"\nTesting prediction endpoint with {len(test_data)} samples:")
    for i, sample in enumerate(test_data):
        print(f"\nSample {i+1}:")
        print(f"Input: {json.dumps(sample, indent=2)}")
        
        try:
            response = requests.post(
                f"{API_URL}/predict", 
                json=sample,
                headers={"Content-Type": "application/json"}
            )
            
            print(f"Status Code: {response.status_code}")
            if response.status_code == 200:
                print(f"Prediction: {json.dumps(response.json(), indent=2)}")
            else:
                print(f"Error: {response.text}")
        except Exception as e:
            print(f"Request failed: {str(e)}")
        
        time.sleep(0.5)  # Small delay between requests

if __name__ == "__main__":
    print("API Test Client")
    print("==============")
    
    if test_health():
        test_prediction_endpoint()
    else:
        print("Health check failed. Is the server running?")
