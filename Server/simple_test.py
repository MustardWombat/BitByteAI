"""
Simple script to verify ML pipeline functionality
"""
import os
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import pickle

# Create directories
os.makedirs("output_models", exist_ok=True)
os.makedirs("collected_data", exist_ok=True)

print("Testing ML pipeline...")

# Create simple synthetic data
print("1. Creating synthetic data...")
# Use 5 features to match what simple_prediction_api.py expects
X = np.random.rand(100, 5)  # 5 features for dayOfWeek, hourOfDay, minuteOfHour, device_activity, device_batteryLevel
y = 5*X[:, 0] + 2*X[:, 1] - 3*X[:, 2] + X[:, 3] - X[:, 4] + np.random.randn(100)*0.1  # Simple relationship with noise

# Train a model
print("2. Training model...")
model = RandomForestRegressor(n_estimators=10)
model.fit(X, y)

# Save the model with the correct name expected by the API
print("3. Saving model...")
model_path = "output_models/NotificationTimePredictor.pkl"  # Changed from SimpleModel.pkl
with open(model_path, 'wb') as f:
    pickle.dump(model, f)

# Test the model
print("4. Testing model...")
test_input = np.array([[0.5, 0.5, 0.5, 0.5, 0.5]])  # Match 5 features
prediction = model.predict(test_input)[0]
print(f"Prediction for test input: {prediction:.4f}")

print("\n✅ Test complete! If you see this message without errors, your environment can run ML code.")
print("Next step: Try running the Flask server.")
