import requests
import json

API_URL = "http://localhost:5001"

def test_server():
    # Test health endpoint
    try:
        health_response = requests.get(f"{API_URL}/health")
        health_data = health_response.json()
        print(f"Health check: {health_data}")
        
        if not health_data.get("model_available"):
            print("Warning: Server is running but no model is available!")
            return False
            
        # Test prediction endpoint
        test_data = {
            "dayOfWeek": 2,
            "hourOfDay": 14,
            "minuteOfHour": 30,
            "device_activity": 0.7,
            "device_batteryLevel": 0.8
        }
        
        pred_response = requests.post(
            f"{API_URL}/predict",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        
        if pred_response.status_code == 200:
            result = pred_response.json()
            print(f"Prediction successful: {result}")
            print(f"Optimal notification time: {result['prediction']}")
            return True
        else:
            print(f"Prediction failed: {pred_response.text}")
            return False
            
    except Exception as e:
        print(f"Error connecting to server: {str(e)}")
        print("Is the server running at http://localhost:5001?")
        return False

if __name__ == "__main__":
    print("Testing prediction API server...")
    success = test_server()
    print(f"Test {'succeeded' if success else 'failed'}!")
