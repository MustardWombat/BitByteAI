#!/bin/bash

echo "==== Bit ML Server Troubleshooter ===="
echo "Current directory: $(pwd)"

# Check if we're in the correct directory
if [ ! -f "prediction_api.py" ]; then
    echo "ERROR: prediction_api.py not found in current directory!"
    echo "Make sure you're running this script from the Server directory."
    exit 1
fi

# Check Python installation
echo "Checking Python installation..."
if ! command -v python &> /dev/null; then
    echo "ERROR: Python not found! Please install Python."
    exit 1
fi

echo "Python version:"
python --version

# Check if port 5001 is already in use
echo "Checking if port 5001 is already in use..."
if lsof -i:5001 &> /dev/null; then
    echo "ERROR: Port 5001 is already in use! Try stopping that process first."
    echo "Running processes using port 5001:"
    lsof -i:5001
    exit 1
else
    echo "Port 5001 is available."
fi

# Check if required directories exist
echo "Checking for output_models directory..."
if [ ! -d "output_models" ]; then
    echo "WARNING: 'output_models' directory not found. Creating it now."
    mkdir -p output_models
fi

# Check for model files
if [ ! -f "output_models/NotificationTimePredictor.mlmodel" ] && [ ! -f "output_models/NotificationTimePredictor.pkl" ]; then
    echo "WARNING: No model files found in output_models directory!"
    echo "The server will start but predictions won't work."
    echo "Run check_models.py to create a test model."
fi

# Check for dependencies
echo "Checking for required Python packages..."
MISSING_DEPS=false

check_package() {
    if ! python -c "import $1" &> /dev/null; then
        echo "WARNING: $1 not installed. Run: pip install $1"
        MISSING_DEPS=true
    else
        echo "✓ $1 installed"
    fi
}

check_package flask
check_package pandas
check_package numpy
check_package requests

if [ "$MISSING_DEPS" = true ]; then
    echo "Some dependencies are missing. Install them before continuing."
    read -p "Install missing packages with pip? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ ! python -c "import flask" &> /dev/null ]; then
            pip install flask
        fi
        if [ ! python -c "import pandas" &> /dev/null ]; then
            pip install pandas
        fi
        if [ ! python -c "import numpy" &> /dev/null ]; then
            pip install numpy
        fi
        if [ ! python -c "import requests" &> /dev/null ]; then
            pip install requests
        fi
    fi
fi

# Try starting the server
echo "Attempting to start the server..."
python prediction_api.py
