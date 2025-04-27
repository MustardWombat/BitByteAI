# Bit Server - Prediction API

This server provides machine learning model predictions for optimal notification timing in the Bit application. It can use either CoreML or scikit-learn models depending on the runtime environment.

## Architecture Overview

The prediction API is a Flask-based web service that:

1. Loads ML models (either CoreML or scikit-learn format)
2. Exposes endpoints for predictions and model information
3. Provides a simple web interface for testing
4. Allows model distribution to client applications

## What It Tracks

The prediction API processes and analyzes:

- **User Behavior Patterns**: Day of week and time of day preferences
- **Device Metrics**: Activity levels, battery levels, screen state
- **Application States**: Whether the app is in foreground, audio playing status
- **User Response Times**: How quickly users respond to notifications
- **Engagement Data**: User interaction with previous notifications

This data is used to predict the optimal time to send notifications to maximize user engagement while respecting user preferences and activity patterns.

## Key Components

### Model Management
- Attempts to load CoreML model first
- Falls back to scikit-learn model if CoreML isn't available
- Supports downloading the latest model files

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Serves the web interface for testing |
| `/predict` | POST | Accepts feature data and returns predictions |
| `/health` | GET | Returns API health status |
| `/download_model` | GET | Downloads the requested model file |
| `/model_info` | GET | Provides metadata about available models |

### Requirements
- Flask
- pandas
- coremltools (optional, for CoreML support)
- scikit-learn

## Setup & Usage

### Installation
```bash
pip install -r requirements.txt
```

### Running the Server
```bash
python prediction_api.py
```
The server will start on port 5001 by default.

### Making Predictions
Send a POST request to `/predict` with JSON data containing feature values:

```bash
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{"dayOfWeek": 3, "hourOfDay": 14, "device_activity": 0.5, "device_batteryLevel": 0.75, "device_screenActive": 1, "device_appInForeground": 0, "device_audioPlaying": 0}'
```

## Model Information

- Models are stored in the `output_models/` directory
- CoreML model: `NotificationTimePredictor.mlmodel`
- scikit-learn model: `NotificationTimePredictor.pkl`
- Prediction target: Optimal time in minutes for sending the next notification
