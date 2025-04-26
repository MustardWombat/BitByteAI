#!/bin/bash
# Deployment script for bitbyte.lol

# Exit on any error
set -e

# Configuration
SERVER_USER="your_username"  # Replace with your SSH username on the bitbyte.lol server
SERVER_HOST="bitbyte.lol"
REMOTE_DIR="/var/www/bitbyte.lol/ml_server"
SOURCE_DIR="$(dirname "$0")"

echo "Deploying ML server to production..."

# 1. SSH to create the directory if it doesn't exist
ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${REMOTE_DIR}"

# 2. Copy all necessary files
echo "Copying files to server..."
rsync -avz --exclude 'venv' --exclude '__pycache__' \
    --exclude '*.pyc' --exclude '.git' \
    ${SOURCE_DIR}/ ${SERVER_USER}@${SERVER_HOST}:${REMOTE_DIR}/

# 3. Set up the environment on the remote server
echo "Setting up environment on server..."
ssh ${SERVER_USER}@${SERVER_HOST} "cd ${REMOTE_DIR} && \
    python3 -m venv venv && \
    source venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements-prod.txt && \
    chmod +x manage.sh run_complete_test.sh"

# 4. Configure Supervisor to manage the process
echo "Setting up Supervisor configuration..."
ssh ${SERVER_USER}@${SERVER_HOST} "sudo tee /etc/supervisor/conf.d/ml_prediction.conf > /dev/null << EOF
[program:ml_prediction]
directory=${REMOTE_DIR}
command=${REMOTE_DIR}/venv/bin/gunicorn --workers=2 --bind=127.0.0.1:5001 wsgi:app
autostart=true
autorestart=true
stderr_logfile=/var/log/ml_prediction.err.log
stdout_logfile=/var/log/ml_prediction.out.log
user=${SERVER_USER}
environment=PATH=\"${REMOTE_DIR}/venv/bin\"
EOF"

# 5. Set up Nginx configuration for the subdomain
echo "Setting up Nginx configuration..."
ssh ${SERVER_USER}@${SERVER_HOST} "sudo tee /etc/nginx/sites-available/ml.bitbyte.lol > /dev/null << EOF
server {
    listen 80;
    server_name ml.bitbyte.lol;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF"

# 6. Enable the site and set up SSL with Let's Encrypt
echo "Enabling site and setting up SSL..."
ssh ${SERVER_USER}@${SERVER_HOST} "sudo ln -sf /etc/nginx/sites-available/ml.bitbyte.lol /etc/nginx/sites-enabled/ && \
    sudo certbot --nginx -d ml.bitbyte.lol -n --agree-tos --email your_email@example.com && \
    sudo nginx -t && \
    sudo systemctl reload nginx"

# 7. Restart Supervisor to apply changes
echo "Restarting services..."
ssh ${SERVER_USER}@${SERVER_HOST} "sudo supervisorctl reread && \
    sudo supervisorctl update && \
    sudo supervisorctl restart ml_prediction"

echo "Deployment complete! Your ML prediction server should now be available at https://ml.bitbyte.lol"
echo "To test: curl -X POST https://ml.bitbyte.lol/predict -H 'Content-Type: application/json' -d '{\"dayOfWeek\": 2, \"hourOfDay\": 14, \"minuteOfHour\": 30, \"device_activity\": 0.7, \"device_batteryLevel\": 0.8}'"
