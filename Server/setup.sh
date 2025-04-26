#!/bin/bash

# Create a virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

echo "Virtual environment set up and dependencies installed!"
echo "To activate the virtual environment, run: source venv/bin/activate"
echo "To start the server, run: python app.py"
