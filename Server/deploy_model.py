#!/usr/bin/env python
import os
import shutil
import subprocess
import argparse
import time
from datetime import datetime

# Constants
SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(SERVER_DIR, "output_models")
BACKUP_DIR = os.path.join(SERVER_DIR, "model_backups")
LOG_FILE = os.path.join(SERVER_DIR, "deployment.log")

# Ensure directories exist
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)

def log_message(message):
    """Log a message to file and console"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    
    with open(LOG_FILE, "a") as f:
        f.write(log_line + "\n")

def backup_current_model():
    """Backup the current model before deploying a new one"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Check if models exist before backing up
    sklearn_model = os.path.join(MODEL_DIR, "NotificationTimePredictor.pkl")
    coreml_model = os.path.join(MODEL_DIR, "NotificationTimePredictor.mlmodel")
    
    if os.path.exists(sklearn_model):
        backup_path = os.path.join(BACKUP_DIR, f"NotificationTimePredictor_{timestamp}.pkl")
        shutil.copy2(sklearn_model, backup_path)
        log_message(f"Backed up sklearn model to {backup_path}")
    
    if os.path.exists(coreml_model):
        backup_path = os.path.join(BACKUP_DIR, f"NotificationTimePredictor_{timestamp}.mlmodel")
        shutil.copy2(coreml_model, backup_path)
        log_message(f"Backed up CoreML model to {backup_path}")

def generate_data():
    """Generate synthetic data for training"""
    log_message("Generating synthetic data...")
    result = subprocess.run(
        ["python", os.path.join(SERVER_DIR, "generate_sample_data.py")],
        capture_output=True,
        text=True
    )
    log_message(result.stdout)
    if result.stderr:
        log_message(f"ERROR: {result.stderr}")
    return result.returncode == 0

def train_model():
    """Run the model training script"""
    log_message("Training model...")
    result = subprocess.run(
        ["python", os.path.join(SERVER_DIR, "train_model.py")],
        capture_output=True,
        text=True
    )
    log_message(result.stdout)
    if result.stderr:
        log_message(f"ERROR: {result.stderr}")
    return result.returncode == 0

def restart_server():
    """Restart the prediction API server"""
    log_message("Restarting API server...")
    
    # This is a simplified example - in production you would use a process manager
    # like systemd, supervisor, or Docker to manage your server process
    
    # Check if server process is running and stop it
    # For demonstration - you might need to adapt this to your environment
    try:
        # For Unix-like systems, find processes using the port
        result = subprocess.run(["lsof", "-i", ":5001"], capture_output=True, text=True)
        if "python" in result.stdout:
            log_message("Stopping existing server process...")
            for line in result.stdout.splitlines():
                if "python" in line:
                    parts = line.split()
                    if len(parts) > 1:
                        pid = parts[1]
                        subprocess.run(["kill", pid])
                        time.sleep(2)  # Give process time to shut down
    except Exception as e:
        log_message(f"Error checking/stopping existing process: {str(e)}")
    
    # Start the server in the background
    log_message("Starting new server process...")
    try:
        # Choose which server implementation to use
        server_script = "simple_prediction_api.py"  # or "prediction_api.py" if pandas is available
        subprocess.Popen(
            ["python", os.path.join(SERVER_DIR, server_script)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True
        )
        log_message(f"Server started using {server_script}")
        return True
    except Exception as e:
        log_message(f"Error starting server: {str(e)}")
        return False

def deploy():
    """Run the full deployment process"""
    log_message("Starting deployment process...")
    
    backup_current_model()
    
    if generate_data():
        if train_model():
            if restart_server():
                log_message("Deployment completed successfully!")
                return True
            else:
                log_message("Failed to restart server")
        else:
            log_message("Model training failed")
    else:
        log_message("Data generation failed")
    
    log_message("Deployment failed!")
    return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy the notification prediction model")
    parser.add_argument("--skip-data", action="store_true", help="Skip data generation step")
    parser.add_argument("--skip-training", action="store_true", help="Skip model training step")
    parser.add_argument("--restart-only", action="store_true", help="Only restart the server")
    
    args = parser.parse_args()
    
    if args.restart_only:
        restart_server()
    else:
        backup_current_model()
        
        if not args.skip_data:
            generate_data()
        else:
            log_message("Skipping data generation")
            
        if not args.skip_training:
            train_model()
        else:
            log_message("Skipping model training")
            
        restart_server()
    
    log_message("Deployment process completed")
