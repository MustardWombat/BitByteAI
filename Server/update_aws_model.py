#!/usr/bin/env python3
"""
Script to update the ML model on your AWS server

This script:
1. Generates a new seed model locally
2. Uploads it to your AWS server
3. Restarts the server service to load the new model
"""

import os
import sys
import subprocess
import argparse
from datetime import datetime

def parse_args():
    parser = argparse.ArgumentParser(description="Update the Bit ML model on AWS")
    parser.add_argument("--key", required=True, help="Path to your AWS .pem key file")
    parser.add_argument("--host", required=True, help="EC2 instance hostname or IP")
    parser.add_argument("--skip-model-creation", action="store_true", 
                        help="Skip model creation, just upload existing model")
    return parser.parse_args()

def run_command(cmd, description=None):
    """Run a shell command and print the result"""
    if description:
        print(f"{description}...")
    
    try:
        result = subprocess.run(cmd, shell=True, check=True, 
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("SUCCESS!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: {e}")
        print(f"Output: {e.stderr.decode('utf-8')}")
        return False

def create_new_model():
    """Create a new seed model using update_seed_model.py"""
    print("Creating new seed model...")
    try:
        # Check if update_seed_model.py exists
        if not os.path.exists("update_seed_model.py"):
            print("ERROR: update_seed_model.py not found in the current directory")
            return False
            
        # Run the script to create new model
        result = subprocess.run(["python", "update_seed_model.py"], check=True)
        
        # Check if the model file was created
        if os.path.exists("output_models/NotificationTimePredictor.pkl"):
            print("New model created successfully!")
            return True
        else:
            print("ERROR: Model file was not created")
            return False
    except subprocess.CalledProcessError as e:
        print(f"ERROR creating model: {e}")
        return False

def upload_model(key_path, host):
    """Upload the model file to the AWS server"""
    if not os.path.exists("output_models/NotificationTimePredictor.pkl"):
        print("ERROR: No model file found to upload")
        return False
        
    # Backup the model with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_cmd = f"ssh -i {key_path} ubuntu@{host} 'mkdir -p ~/model_backups && " \
                f"cp ~/bit-ml-server/output_models/NotificationTimePredictor.pkl " \
                f"~/model_backups/NotificationTimePredictor_{timestamp}.pkl 2>/dev/null || true'"
    
    run_command(backup_cmd, "Backing up existing model on server")
    
    # Upload the new model
    upload_cmd = f"scp -i {key_path} output_models/NotificationTimePredictor.pkl " \
                f"ubuntu@{host}:~/bit-ml-server/output_models/"
    
    return run_command(upload_cmd, "Uploading new model to server")

def restart_server(key_path, host):
    """Restart the server service to load the new model"""
    restart_cmd = f"ssh -i {key_path} ubuntu@{host} 'sudo systemctl restart bit-ml-server'"
    return run_command(restart_cmd, "Restarting server service")

def verify_server(host):
    """Verify that the server is running with the new model"""
    verify_cmd = f"curl -s http://{host}:5001/health"
    try:
        result = subprocess.run(verify_cmd, shell=True, check=True, 
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"Server health check: {result.stdout.decode('utf-8')}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Server verification failed: {e}")
        return False

if __name__ == "__main__":
    args = parse_args()
    
    print("===== Bit ML Model Updater =====")
    print(f"Target server: {args.host}")
    
    success = True
    
    if not args.skip_model_creation:
        success = create_new_model()
    
    if success:
        if upload_model(args.key, args.host):
            if restart_server(args.key, args.host):
                print("\nWaiting for server to restart...")
                import time
                time.sleep(5)  # Give the server time to restart
                
                if verify_server(args.host):
                    print("\n✅ Success! The model has been updated and the server restarted.")
                    print(f"  You can test it at: http://{args.host}:5001")
                else:
                    print("\n❌ Model was uploaded but the server may not be running correctly.")
            else:
                print("\n❌ Failed to restart the server.")
        else:
            print("\n❌ Failed to upload the model.")
    else:
        print("\n❌ Failed to create the model.")
