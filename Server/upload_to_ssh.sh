#!/bin/bash
# Simple script to upload Flask ML application to an SSH server

# Configuration - REPLACE THESE VALUES
SSH_USER="your_username"      # Your SSH username
SSH_HOST="your_server_host"   # Your server hostname or IP
SSH_PORT="22"                 # SSH port (usually 22)
SSH_KEY=""                    # Path to SSH key (leave empty for password auth)
REMOTE_DIR="/home/$SSH_USER/ml_server"  # Remote directory

# Local project directory
LOCAL_DIR="$(dirname "$0")"

echo "=== ML Server Upload Script ==="
echo "Uploading to $SSH_USER@$SSH_HOST:$REMOTE_DIR"

# Create remote directory if it doesn't exist
if [ -n "$SSH_KEY" ]; then
    ssh -i "$SSH_KEY" -p $SSH_PORT $SSH_USER@$SSH_HOST "mkdir -p $REMOTE_DIR"
else
    ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "mkdir -p $REMOTE_DIR"
fi

# Upload files
echo "Uploading files..."
if [ -n "$SSH_KEY" ]; then
    rsync -avz -e "ssh -i $SSH_KEY -p $SSH_PORT" \
        --exclude 'venv' --exclude '__pycache__' \
        --exclude '*.pyc' --exclude '.git' \
        $LOCAL_DIR/ $SSH_USER@$SSH_HOST:$REMOTE_DIR/
else
    rsync -avz -e "ssh -p $SSH_PORT" \
        --exclude 'venv' --exclude '__pycache__' \
        --exclude '*.pyc' --exclude '.git' \
        $LOCAL_DIR/ $SSH_USER@$SSH_HOST:$REMOTE_DIR/
fi

echo "Upload complete! Files are now on the server at $REMOTE_DIR"
echo ""
echo "Next steps:"
echo "1. SSH into your server: ssh $SSH_USER@$SSH_HOST -p $SSH_PORT"
echo "2. Navigate to the directory: cd $REMOTE_DIR"
echo "3. Set up a Python virtual environment: python3 -m venv venv"
echo "4. Activate it: source venv/bin/activate"
echo "5. Install dependencies: pip install -r requirements.txt"
echo "6. Run the test: python simple_test.py"
echo "7. Start the server: python simple_prediction_api.py"
echo ""
echo "For production use, consider setting up a systemd service or using screen/tmux"
echo "to keep the server running after you disconnect."
