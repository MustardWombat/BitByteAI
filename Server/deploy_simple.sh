#!/bin/bash

# A simpler deployment script that works on most Linux servers
# Replace these with your actual server details
SERVER_USER="your_username"  # Your SSH username on your server
SERVER_IP="your_server_ip"   # Your server's IP address
SERVER_DIR="/home/$SERVER_USER/ml_server"

echo "Deploying ML server..."

# 1. Create directory structure on server
echo "Creating directories..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_DIR/static"

# 2. Copy files to server
echo "Copying files..."
rsync -avz --exclude 'venv' --exclude '__pycache__' \
    --exclude '*.pyc' --exclude '.git' \
    ./ $SERVER_USER@$SERVER_IP:$SERVER_DIR/

# 3. Set up environment and install dependencies
echo "Setting up environment..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_DIR && \
    python3 -m venv venv && \
    source venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install numpy scikit-learn Flask requests gunicorn && \
    chmod +x run_complete_test.sh"

# 4. Run the test to make sure everything works
echo "Testing the setup..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_DIR && \
    source venv/bin/activate && \
    python simple_test.py"

# 5. Start the server using tmux (keeps it running after you disconnect)
echo "Starting the server..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_DIR && \
    source venv/bin/activate && \
    tmux new-session -d -s ml_server 'python simple_prediction_api.py'"

echo "Deployment complete! Your server should be running on port 5001."
echo "Next: Configure your domain to point to your server IP"
