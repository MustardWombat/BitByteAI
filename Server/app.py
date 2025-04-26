from flask import Flask, request, jsonify, send_file, render_template
import os
import json
from datetime import datetime
import pandas as pd
import glob

app = Flask(__name__)

# Directory to store incoming data
DATA_DIR = "collected_data"
os.makedirs(DATA_DIR, exist_ok=True)

# Directory to store output models
OUTPUT_DIR = "output_models"
os.makedirs(OUTPUT_DIR, exist_ok=True)

@app.route('/api/submit-study-data', methods=['POST'])
def submit_study_data():
    try:
        # Get the data payload
        data = request.json
        
        # Validate required fields
        if not data or 'deviceContext' not in data or 'sessions' not in data:
            return jsonify({"error": "Invalid data format"}), 400
        
        # Create unique ID for this submission
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        device_id = data.get('deviceContext', {}).get('deviceType', 'unknown')
        filename = f"{timestamp}_{device_id}.json"
        
        # Save raw data
        with open(os.path.join(DATA_DIR, filename), 'w') as f:
            json.dump(data, f)
        
        # Process data for ML training (in production, you'd queue this for async processing)
        process_data_for_ml(data)
        
        return jsonify({"success": True, "message": "Data received successfully"}), 200
    
    except Exception as e:
        print(f"Error processing submission: {str(e)}")
        return jsonify({"error": str(e)}), 500

def process_data_for_ml(data):
    """Convert JSON data to DataFrame format suitable for ML training"""
    try:
        sessions = data['sessions']
        if not sessions:
            return
            
        # Convert to DataFrame for easier processing
        df = pd.DataFrame(sessions)
        
        # Add any device context as columns
        for key, value in data['deviceContext'].items():
            df[f"device_{key}"] = value
            
        # Save as CSV for ML processing
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        df.to_csv(os.path.join(DATA_DIR, f"processed_{timestamp}.csv"), index=False)
    except Exception as e:
        print(f"Error processing data for ML: {str(e)}")

@app.route('/api/models/latest', methods=['GET'])
def get_latest_model():
    """Return the latest ML model"""
    model_path = os.path.join(OUTPUT_DIR, "NotificationTimePredictor.mlmodel")
    
    if not os.path.exists(model_path):
        return jsonify({"error": "No model available"}), 404
        
    # Get model creation time
    model_time = os.path.getmtime(model_path)
    model_time_str = datetime.fromtimestamp(model_time).strftime("%Y-%m-%d %H:%M:%S")
    
    # Return model file
    return send_file(
        model_path,
        mimetype='application/octet-stream',
        as_attachment=True,
        download_name=f"NotificationTimePredictor_{model_time_str}.mlmodel"
    )

@app.route('/dashboard')
def dashboard():
    """Render the data collection dashboard"""
    # Count total sessions collected
    total_sessions = 0
    submissions = []
    
    # Get list of all data files
    data_files = glob.glob(os.path.join(DATA_DIR, "*.json"))
    data_files.sort(key=os.path.getmtime, reverse=True)
    
    # Calculate stats and prepare submission list
    unique_devices = set()
    for file_path in data_files:
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
                
            # Count sessions
            session_count = len(data.get('sessions', []))
            total_sessions += session_count
            
            # Track unique devices
            device_id = data.get('deviceContext', {}).get('deviceType', 'unknown')
            unique_devices.add(device_id)
            
            # Add to submissions list (limit to 10 most recent)
            if len(submissions) < 10:
                timestamp = datetime.fromtimestamp(os.path.getmtime(file_path)).strftime("%Y-%m-%d %H:%M:%S")
                submissions.append({
                    'timestamp': timestamp,
                    'device_type': device_id,
                    'session_count': session_count
                })
        except:
            continue
    
    # Get model performance info
    model_path = os.path.join(OUTPUT_DIR, "NotificationTimePredictor.mlmodel")
    if os.path.exists(model_path):
        model_version = datetime.fromtimestamp(os.path.getmtime(model_path)).strftime("%Y-%m-%S %H:%M:%S")
        
        # In a real app, you'd store and retrieve the actual accuracy
        model_accuracy = "85%" 
    else:
        model_version = "None"
        model_accuracy = "N/A"
    
    # Prepare chart data - submissions per day for the last 30 days
    today = datetime.now().date()
    chart_labels = [(today - pd.Timedelta(days=i)).strftime("%Y-%m-%d") for i in range(30)]
    chart_labels.reverse()
    
    # Count submissions per day
    submissions_by_day = {}
    for file_path in data_files:
        file_date = datetime.fromtimestamp(os.path.getmtime(file_path)).date().strftime("%Y-%m-%d")
        if file_date in chart_labels:
            submissions_by_day[file_date] = submissions_by_day.get(file_date, 0) + 1
    
    chart_data = [submissions_by_day.get(day, 0) for day in chart_labels]
    
    return render_template('dashboard.html',
                          total_sessions=total_sessions,
                          total_users=len(unique_devices),
                          last_update=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                          model_version=model_version,
                          model_accuracy=model_accuracy,
                          submissions=submissions,
                          chart_labels=json.dumps(chart_labels),
                          chart_data=json.dumps(chart_data))

@app.route('/api/train-model', methods=['POST'])
def api_train_model():
    """API endpoint to trigger model training"""
    try:
        # In a real app, you'd queue this job to run asynchronously
        # For demo purposes, we'll just import and call the training script
        from train_model import load_and_prepare_data, train_notification_time_model
        
        data = load_and_prepare_data()
        if data is not None:
            model_path = train_notification_time_model(data)
            return jsonify({"success": True, "model_path": model_path})
        else:
            return jsonify({"success": False, "error": "No data available for training"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

if __name__ == '__main__':
    # For production with a real domain, use these settings:
    # app.run(debug=False, host='0.0.0.0', port=80)
    
    # For development/testing:
    app.run(debug=True, host='0.0.0.0', port=5000)
