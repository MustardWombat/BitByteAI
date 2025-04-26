from flask import Flask, request, jsonify, send_from_directory
import os
import pickle
import numpy as np
import sys

app = Flask(__name__, static_url_path='', static_folder='static')

# Constants
SKLEARN_MODEL_PATH = "output_models/NotificationTimePredictor.pkl"
PORT = 5001

# Function to load the model
def load_model():
    if os.path.exists(SKLEARN_MODEL_PATH):
        try:
            with open(SKLEARN_MODEL_PATH, 'rb') as f:
                return pickle.load(f)
        except Exception as e:
            print(f"Error loading scikit-learn model: {str(e)}")
            return None
    return None

model = load_model()

# Serve the web interface
@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({"error": "No model available for prediction"}), 404
    
    # Get features from request
    data = request.json
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    try:
        # Convert input data to numpy array in the right order
        # You'll need to know the exact feature order your model expects
        feature_order = ['dayOfWeek', 'hourOfDay', 'minuteOfHour', 
                        'device_activity', 'device_batteryLevel']
        
        # Extract features in the correct order
        features = []
        for feature in feature_order:
            if feature in data:
                features.append(float(data[feature]))
            else:
                # Use a default value if the feature is missing
                features.append(0.0)
        
        # Convert to numpy array and reshape for prediction
        features_array = np.array(features).reshape(1, -1)
        
        # Make prediction
        prediction = model.predict(features_array)[0]
        result = float(prediction)
        
        return jsonify({
            "prediction": result,
            "status": "success"
        })
        
    except Exception as e:
        return jsonify({"error": f"{str(e)}"}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "model_available": model is not None})

if __name__ == '__main__':
    print(f"Starting simple server on port {PORT}")
    print(f"Web interface available at http://localhost:{PORT}/")
    app.run(debug=True, host='0.0.0.0', port=PORT)
