#!/bin/bash

# Deployment script for PythonAnywhere
echo "Deploying ML server to PythonAnywhere..."

# Configuration
PA_USERNAME="your_pythonanywhere_username"
PA_DOMAIN="${PA_USERNAME}.pythonanywhere.com"
PA_API_TOKEN="your_api_token"  # Generate in Account > API Token

# 1. Create a ZIP file of the project
echo "Creating ZIP file..."
cd "$(dirname "$0")"
zip -r ml_server.zip . -x "*.git*" "venv/*" "__pycache__/*" "*.pyc"

# 2. Upload the ZIP file using the PythonAnywhere API
echo "Uploading to PythonAnywhere..."
curl -X POST \
  -H "Authorization: Token ${PA_API_TOKEN}" \
  -F "content=@ml_server.zip" \
  https://www.pythonanywhere.com/api/v0/user/${PA_USERNAME}/files/path/home/${PA_USERNAME}/ml_server.zip

# 3. SSH to set up the environment (you'll need to enter your password)
echo "Setting up the environment on PythonAnywhere..."
ssh ${PA_USERNAME}@ssh.pythonanywhere.com << EOF
  # Extract the ZIP file
  cd ~
  rm -rf ml_server
  mkdir -p ml_server
  unzip -o ml_server.zip -d ml_server
  cd ml_server
  
  # Set up virtual environment
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  
  # Create a test model
  python simple_test.py
  
  # Configure the web app (requires manual steps in the PythonAnywhere dashboard)
  echo "Next steps:"
  echo "1. Go to the PythonAnywhere dashboard: https://www.pythonanywhere.com/"
  echo "2. Go to the Web tab and create a new web app"
  echo "3. Select Flask and Python 3.9"
  echo "4. Set Source code to: /home/${PA_USERNAME}/ml_server"
  echo "5. Set Working directory to: /home/${PA_USERNAME}/ml_server"
  echo "6. Set WSGI configuration file to point to wsgi.py"
  echo "7. Add custom domain: ml.bitbyte.lol in the Web tab"
EOF

echo "Done! Follow the steps above to complete setup."
