#!/bin/bash

echo "===== AWS Deployment for Bit ML Server ====="
echo "This script will help you prepare your files for AWS deployment."

# Prepare deployment package
echo "Creating deployment package..."
mkdir -p deploy
cp prediction_api.py deploy/
cp -r static deploy/
mkdir -p deploy/output_models

# Create requirements file
echo "Creating requirements.txt..."
cat > deploy/requirements.txt << EOL
flask==2.0.1
pandas==1.3.3
numpy==1.21.2
scikit-learn==0.24.2
gunicorn==20.1.0
EOL

# Create systemd service file
echo "Creating service file for automatic startup..."
cat > deploy/bit-ml-server.service << EOL
[Unit]
Description=Bit ML Prediction API Server
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/bit-ml-server
ExecStart=/home/ubuntu/bit-ml-server/venv/bin/gunicorn --bind 0.0.0.0:5001 prediction_api:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Create setup instructions
cat > deploy/README.md << EOL
# Bit ML Server - AWS Deployment

Follow these steps to set up the server on AWS:

1. Transfer all files to your EC2 instance:
   \`\`\`
   scp -r -i /path/to/your-key.pem deploy/* ubuntu@your-ec2-instance:/home/ubuntu/bit-ml-server/
   \`\`\`

2. SSH into your instance:
   \`\`\`
   ssh -i /path/to/your-key.pem ubuntu@your-ec2-instance
   \`\`\`

3. Set up Python environment:
   \`\`\`
   cd bit-ml-server
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   \`\`\`

4. Install service file:
   \`\`\`
   sudo cp bit-ml-server.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable bit-ml-server
   sudo systemctl start bit-ml-server
   \`\`\`

5. Check status:
   \`\`\`
   sudo systemctl status bit-ml-server
   \`\`\`

6. Open port in security group:
   - Go to AWS Console > EC2 > Security Groups
   - Add inbound rule for TCP port 5001
EOL

echo "Done! Deployment files created in the 'deploy' directory."
echo "See deploy/README.md for AWS installation instructions."
