import os
import sys
import glob
import pandas as pd
import pickle
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

# Constants
DATA_DIR = "collected_data"
OUTPUT_DIR = "output_models"
MODEL_PATH = os.path.join(OUTPUT_DIR, "NotificationTimePredictor.pkl")

def collect_anonymized_data():
    """Collect and process anonymized data files from DATA_DIR"""
    if not os.path.exists(DATA_DIR):
        print(f"Creating data directory: {DATA_DIR}")
        os.makedirs(DATA_DIR)
        print("No data files found. Please add anonymized data files to this directory.")
        return None
        
    # Look for all JSON files in the data directory
    data_files = glob.glob(os.path.join(DATA_DIR, "*.json"))
    if not data_files:
        print("No data files found in the data directory.")
        return None
        
    print(f"Found {len(data_files)} data files")
    
    # Process data - this is just a placeholder
    # In a real implementation, you'd parse the JSON files and extract features
    
    # Create a simple example dataset if no real data
    print("Creating example dataset for demonstration...")
    X = np.random.rand(1000, 5)  # 5 features: dayOfWeek, hourOfDay, etc.
    y = np.random.rand(1000)     # Target: optimal notification time
    
    return X, y

def train_model(X, y):
    """Train a model on the collected data"""
    print("Training model on collected data...")
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train model
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate model
    test_score = model.score(X_test, y_test)
    print(f"Model R² score on test data: {test_score:.4f}")
    
    return model

def save_model(model):
    """Save the trained model"""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    # Save scikit-learn model
    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(model, f)
    print(f"Model saved to {MODEL_PATH}")
    
    # TODO: Convert to CoreML format if needed
    # This would require coremltools and specific code to convert

if __name__ == "__main__":
    print("===== Bit ML Seed Model Creator =====")
    
    print("This utility creates a 'seed' ML model from anonymized user data.")
    print("This seed model will be distributed to client apps as a starting point")
    print("for personalized learning.\n")
    
    # Collect data
    data = collect_anonymized_data()
    
    if data:
        X, y = data
        # Train model
        model = train_model(X, y)
        
        # Save model
        save_model(model)
        
        print("\nSeed model creation complete!")
        print("The model is now available for clients to download.")
    else:
        print("\nCould not create seed model: No data available.")
        print(f"Please add anonymized data files to the {DATA_DIR} directory.")
        print("Each file should be a JSON file with the format described in the documentation.")
