"""
ModelManager - Client-side model management for the Bit app

This script handles:
1. Downloading the seed model from the server
2. Updating the model with local user data
3. Making predictions using the personalized model
"""

import os
import requests
import pickle
import json
import numpy as np
from datetime import datetime

class ModelManager:
    def __init__(self, server_url="https://ml.yourdomain.com", 
                 local_model_path="local_model.pkl"):
        """
        Initialize the ModelManager with your AWS-hosted domain
        
        Args:
            server_url: Your AWS server URL (preferably with HTTPS)
            local_model_path: Where to store the local model file
        """
        self.server_url = server_url
        self.local_model_path = local_model_path
        self.model = self._load_local_model()
        
    def _load_local_model(self):
        """Load locally stored model if it exists"""
        if os.path.exists(self.local_model_path):
            try:
                with open(self.local_model_path, 'rb') as f:
                    return pickle.load(f)
            except Exception as e:
                print(f"Error loading local model: {e}")
        return None
        
    def check_for_updates(self):
        """Check if a newer seed model is available on the server"""
        try:
            response = requests.get(f"{self.server_url}/model_info")
            if response.status_code == 200:
                server_info = response.json()
                
                # Check if we have a local model
                if not os.path.exists(self.local_model_path):
                    return True  # No local model, definitely need update
                
                # Check modification time
                local_mtime = os.path.getmtime(self.local_model_path)
                server_mtime = server_info.get("latest_update")
                
                if server_mtime and server_mtime > local_mtime:
                    return True  # Server has newer model
            
            return False  # No update needed
            
        except Exception as e:
            print(f"Error checking for updates: {e}")
            return False
            
    def download_seed_model(self):
        """Download the latest seed model from server"""
        try:
            response = requests.get(f"{self.server_url}/download_model")
            if response.status_code == 200:
                with open(self.local_model_path, 'wb') as f:
                    f.write(response.content)
                self.model = self._load_local_model()
                return True
            else:
                print(f"Error downloading model: {response.text}")
                return False
        except Exception as e:
            print(f"Error downloading model: {e}")
            return False
            
    def update_with_local_data(self, X, y):
        """Update model with local user data
        
        This is a simplified implementation - in a real app,
        you'd likely use incremental learning or other approaches
        to avoid overfitting to recent data.
        """
        if self.model is None:
            print("No model available to update")
            return False
            
        try:
            # This assumes the model has a partial_fit method
            # You might need to adjust based on your model type
            self.model.fit(X, y)
            
            # Save updated model
            with open(self.local_model_path, 'wb') as f:
                pickle.dump(self.model, f)
                
            return True
        except Exception as e:
            print(f"Error updating model: {e}")
            return False
            
    def predict(self, features):
        """Make a prediction using the local model"""
        if self.model is None:
            raise ValueError("No model available")
            
        # Convert input to proper format
        if isinstance(features, dict):
            # Convert dict to array (adjust based on your model's requirements)
            feature_names = ['dayOfWeek', 'hourOfDay', 'minuteOfHour', 
                           'device_activity', 'device_batteryLevel']
            X = np.array([[features.get(name, 0) for name in feature_names]])
        else:
            X = features
            
        # Make prediction
        return self.model.predict(X)[0]

# Example usage
if __name__ == "__main__":
    manager = ModelManager()
    
    # Check for and download updates
    if manager.check_for_updates():
        print("Downloading updated seed model...")
        manager.download_seed_model()
    
    # Example prediction
    features = {
        "dayOfWeek": 2,
        "hourOfDay": 14,
        "minuteOfHour": 30,
        "device_activity": 0.7,
        "device_batteryLevel": 0.8
    }
    
    try:
        result = manager.predict(features)
        print(f"Prediction result: {result}")
    except Exception as e:
        print(f"Error making prediction: {e}")
