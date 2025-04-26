#!/bin/bash

# AWS Deployment Script
# This script deploys your ML server to an AWS EC2 instance

set -e  # Exit on any error

# Configuration - REPLACE THESE VALUES
AWS_KEY_PATH="$HOME/.ssh/your-key.pem"    # Update this with the actual path to your key file
EC2_USER="ubuntu"                         # Usually "ubuntu" for Ubuntu AMIs
EC2_IP="3.137.215.156"                    # Your EC2 instance's IP address
EC2_DOMAIN="ml.bitbyte.lol"               # Your subdomain

# Local paths
PROJECT_DIR="$(dirname "$0")"
LOCAL_ZIP="$PROJECT_DIR/ml_server.zip"

# Remote paths
REMOTE_DIR="/home/$EC2_USER/ml_server"
SYSTEMD_SERVICE_PATH="/etc/systemd/system/ml-server.service"

echo "=== ML Server AWS Deployment ==="
echo "Deploying to: $EC2_IP ($EC2_DOMAIN)"

# 1. Create a ZIP file of the project
echo "Creating deployment package..."
cd "$PROJECT_DIR"
zip -r "$LOCAL_ZIP" . -x "*.git*" "venv/*" "__pycache__/*" "*.pyc" "*.zip"

# 2. Create remote directory and copy files
echo "Setting up remote directory..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "mkdir -p $REMOTE_DIR"

echo "Copying files to server..."
scp -i "$AWS_KEY_PATH" "$LOCAL_ZIP" $EC2_USER@$EC2_IP:~
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "unzip -o ~/ml_server.zip -d $REMOTE_DIR && rm ~/ml_server.zip"

# 3. Install dependencies and set up environment
echo "Setting up environment and installing dependencies..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "sudo apt-get update && \
    sudo apt-get install -y python3-venv python3-pip nginx certbot python3-certbot-nginx && \
    cd $REMOTE_DIR && \
    python3 -m venv venv && \
    source venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install -r requirements-prod.txt && \
    pip install numpy scikit-learn Flask gunicorn && \
    chmod +x run_complete_test.sh"

# 4. Run the test to create a model
echo "Creating test model..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "cd $REMOTE_DIR && \
    source venv/bin/activate && \
    python3 simple_test.py"

# 5. Set up systemd service
echo "Setting up systemd service..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "sudo bash -c 'cat > $SYSTEMD_SERVICE_PATH << EOF
[Unit]
Description=ML Prediction Server
After=network.target

[Service]
User=$EC2_USER
WorkingDirectory=$REMOTE_DIR
ExecStart=$REMOTE_DIR/venv/bin/gunicorn --workers=2 --bind=0.0.0.0:5001 wsgi:app
Restart=always
Environment=\"PATH=$REMOTE_DIR/venv/bin\"

[Install]
WantedBy=multi-user.target
EOF'"

# 6. Configure Nginx as reverse proxy
echo "Configuring Nginx..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "sudo bash -c 'cat > /etc/nginx/sites-available/$EC2_DOMAIN << EOF
server {
    server_name $EC2_DOMAIN;

    # Static files with caching
    location ~* \.(css|js|html|png|jpg|jpeg|gif|ico)$ {
        root $REMOTE_DIR/static;
        expires 7d;
        add_header Cache-Control \"public, max-age=604800\";
    }

    # API with rate limiting
    location /predict {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        
        # Basic rate limiting
        limit_req_zone=\\$binary_remote_addr zone=mlapi:10m rate=10r/s;
        limit_req zone=mlapi burst=20 nodelay;
    }

    # Default handler
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
    }
}
EOF'"

# 7. Enable the site and get SSL certificate
echo "Enabling Nginx site and setting up SSL..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "sudo ln -sf /etc/nginx/sites-available/$EC2_DOMAIN /etc/nginx/sites-enabled/ && \
    sudo rm -f /etc/nginx/sites-enabled/default && \
    sudo nginx -t && \
    sudo systemctl restart nginx && \
    sudo systemctl enable ml-server && \
    sudo systemctl start ml-server"

echo "Setting up SSL certificate with Let's Encrypt..."
ssh -i "$AWS_KEY_PATH" $EC2_USER@$EC2_IP "sudo certbot --nginx -d $EC2_DOMAIN --non-interactive --agree-tos --email your-email@example.com"

echo "=== Deployment Complete ==="
echo "Your ML server should now be available at: https://$EC2_DOMAIN"
echo "To test: curl -X POST https://$EC2_DOMAIN/predict -H 'Content-Type: application/json' -d '{\"dayOfWeek\": 2, \"hourOfDay\": 14, \"minuteOfHour\": 30, \"device_activity\": 0.7, \"device_batteryLevel\": 0.8}'"

# 8. Clean up local zip file
echo "Cleaning up..."
rm -f "$LOCAL_ZIP"

echo "Done!"
