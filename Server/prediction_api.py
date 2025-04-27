from flask import Flask, request, jsonify, send_from_directory
import pandas as pd
import os
import pickle
import sys

print("Flask imported successfully!")  # Add this line to confirm Flask is imported

app = Flask(__name__, static_url_path='', static_folder='static')

# Constants
MODEL_PATH = "output_models/NotificationTimePredictor.mlmodel"
SKLEARN_MODEL_PATH = "output_models/NotificationTimePredictor.pkl"
PORT = 5001  # Changed from 5000 to avoid conflict with AirPlay

# Try to load the model - first check if we can use CoreML
use_coreml = False

try:
    import coremltools as ct
    def load_coreml_model():
        if not os.path.exists(MODEL_PATH):
            print(f"CoreML model not found at {MODEL_PATH}")
            return None
        print(f"Loading CoreML model from {MODEL_PATH}")
        return ct.models.MLModel(MODEL_PATH)
except ImportError:
    print("CoreML not available. Will attempt to use scikit-learn model if available.")

# Function to load the appropriate model
def load_model():
    global use_coreml  # Declare use_coreml as global
    if use_coreml:
        try:
            return load_coreml_model()
        except Exception as e:
            print(f"Error loading CoreML model: {str(e)}")
            use_coreml = False  # Update the global variable if CoreML fails
    
    # Fallback to scikit-learn model if CoreML fails
    if os.path.exists(SKLEARN_MODEL_PATH):
        try:
            with open(SKLEARN_MODEL_PATH, 'rb') as f:
                return pickle.load(f)
        except Exception as e:
            print(f"Error loading scikit-learn model: {str(e)}")
            return None
    
    return None

model = load_model()
model_type = "coreml" if use_coreml else "sklearn"

# Serve the web interface
@app.route('/')
def index():source venv/bin/activatessh -i /Users/james_williams/Documents/AWS/BitByteAI.pem ec2-user@3.135.198.218
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
        if model_type == "coreml":
            # CoreML prediction
            input_dict = {k: [float(v)] for k, v in data.items()}
            prediction = model.predict(input_dict)
            result = float(prediction["notificationTime"][0])
        else:
            # Scikit-learn prediction
            # Convert to dataframe with expected features
            features = pd.DataFrame([data])
            prediction = model.predict(features)[0]
            result = float(prediction)
        
        return jsonify({
            "prediction": result,
            "model_type": model_type,
            "status": "success"
        })
        
    except Exception as e:
        return jsonify({"error": f"{str(e)}", "model_type": model_type}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "model_available": model is not None})

# Add new endpoint to distribute the model file
@app.route('/download_model', methods=['GET'])
def download_model():
    """Endpoint for the app to download the latest seed model"""
    model_type = request.args.get('type', 'sklearn')
    
    if model_type == 'coreml' and os.path.exists(MODEL_PATH):
        return send_from_directory('output_models', os.path.basename(MODEL_PATH), 
                                 as_attachment=True)
    elif os.path.exists(SKLEARN_MODEL_PATH):
        return send_from_directory('output_models', os.path.basename(SKLEARN_MODEL_PATH),
                                 as_attachment=True)
    else:
        return jsonify({"error": "Requested model not available"}), 404

# Add model info endpoint to check if new model is available
@app.route('/model_info', methods=['GET'])
def model_info():
    """Returns information about available models and their versions"""
    info = {
        "available_models": [],
        "latest_update": None
    }
    
    # Check CoreML model
    if os.path.exists(MODEL_PATH):
        model_stats = os.stat(MODEL_PATH)
        info["available_models"].append({
            "type": "coreml",
            "size_bytes": model_stats.st_size,
            "last_modified": model_stats.st_mtime,
        })
        info["latest_update"] = max(info["latest_update"] or 0, model_stats.st_mtime)
    
    # Check sklearn model
    if os.path.exists(SKLEARN_MODEL_PATH):
        model_stats = os.stat(SKLEARN_MODEL_PATH)
        info["available_models"].append({
            "type": "sklearn",
            "size_bytes": model_stats.st_size,
            "last_modified": model_stats.st_mtime,
        })
        info["latest_update"] = max(info["latest_update"] or 0, model_stats.st_mtime)
    
    return jsonify(info)

if __name__ == '__main__':
    try:
        # Check if the output_models directory exists
        if not os.path.exists("output_models"):
            print("WARNING: output_models directory not found, creating it now")
            os.makedirs("output_models")
            
        # Check if any model files exist
        if not os.path.exists(MODEL_PATH) and not os.path.exists(SKLEARN_MODEL_PATH):
            print("ERROR: No model files found in output_models directory!")
            print(f"  - CoreML model path: {MODEL_PATH}")
            print(f"  - sklearn model path: {SKLEARN_MODEL_PATH}")
            print("Run check_models.py to create a test model or add model files manually.")
        
        print(f"Starting server on port {PORT}")
        print(f"Web interface available at http://localhost:{PORT}/")
        print(f"Model status: {'Loaded successfully' if model else 'NOT LOADED - API will return errors'}")
        app.run(debug=True, host='0.0.0.0', port=PORT)
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"ERROR: Port {PORT} is already in use! Another server might be running.")
            print("Try: lsof -i:5001 to see which process is using this port.")
            print("Kill the process with: kill <PID>")
        else:
            print(f"ERROR: {str(e)}")
    except Exception as e:
        print(f"ERROR: Failed to start server: {str(e)}")
