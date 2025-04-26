import os
import sys
import subprocess
import platform
import socket

def check_port():
    """Check if port 5001 is available"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('127.0.0.1', 5001))
    if result == 0:
        print("⚠️ ERROR: Port 5001 is already in use by another application")
        if platform.system() == 'Darwin':  # macOS
            print("Running: lsof -i:5001")
            os.system("lsof -i:5001")
        elif platform.system() == 'Linux':
            print("Running: ss -lptn 'sport = :5001'")
            os.system("ss -lptn 'sport = :5001'")
        elif platform.system() == 'Windows':
            print("Running: netstat -ano | findstr :5001")
            os.system("netstat -ano | findstr :5001")
        return False
    sock.close()
    print("✓ Port 5001 is available")
    return True

def check_dependencies():
    """Check if required Python packages are installed"""
    required_packages = ["flask", "pandas", "requests", "numpy"]
    missing = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package} is installed")
        except ImportError:
            missing.append(package)
            print(f"✗ {package} is NOT installed")
    
    if missing:
        print("\nMissing dependencies. Install them with:")
        print(f"pip install {' '.join(missing)}")
        return False
    return True

def check_model_files():
    """Check if model files exist"""
    coreml_path = "output_models/NotificationTimePredictor.mlmodel"
    sklearn_path = "output_models/NotificationTimePredictor.pkl"
    
    if not os.path.exists("output_models"):
        print("✗ output_models directory doesn't exist")
        return False
    
    found = False
    if os.path.exists(coreml_path):
        print(f"✓ Found CoreML model: {coreml_path}")
        found = True
    else:
        print(f"✗ Missing CoreML model: {coreml_path}")
    
    if os.path.exists(sklearn_path):
        print(f"✓ Found scikit-learn model: {sklearn_path}")
        found = True
    else:
        print(f"✗ Missing scikit-learn model: {sklearn_path}")
    
    return found

def run_simple_test():
    """Try starting the server briefly to check for issues"""
    print("\nAttempting to start the server temporarily...")
    try:
        process = subprocess.Popen(
            [sys.executable, "prediction_api.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait for a short time to see if the server starts
        import time
        time.sleep(2)
        
        # Check if process is still running
        if process.poll() is None:
            print("✓ Server started successfully!")
            print("  Press Ctrl+C to stop the server after testing")
            
            # Test health endpoint
            import requests
            try:
                response = requests.get("http://localhost:5001/health", timeout=1)
                print(f"✓ Health endpoint responded: {response.json()}")
            except Exception as e:
                print(f"✗ Health endpoint test failed: {e}")
                
            # Terminate the process
            process.terminate()
            return True
        else:
            # Process exited early - get the output
            stdout, stderr = process.communicate()
            print("✗ Server failed to start!")
            print("\nOutput:")
            print(stdout.decode('utf-8'))
            print("\nErrors:")
            print(stderr.decode('utf-8'))
            return False
    except Exception as e:
        print(f"✗ Error during server test: {e}")
        return False

def explain_architecture():
    """Explain the federated learning architecture"""
    print("\n===== FEDERATED LEARNING ARCHITECTURE =====")
    print("This system uses a federated learning approach:")
    print("1. The server hosts a 'seed' ML model trained on anonymous data")
    print("2. Client apps download this seed model via /download_model endpoint")
    print("3. Each client app personalizes the model with local user data")
    print("4. Predictions become increasingly tailored to individual users")
    print("\nThe server endpoints are:")
    print("- /health - Check if server is running")
    print("- /predict - Make a prediction using the server's model")
    print("- /download_model - Download the latest seed model")
    print("- /model_info - Get metadata about available models")

if __name__ == "__main__":
    print("===== Bit ML Server Diagnostic Tool =====")
    print(f"Current directory: {os.getcwd()}")
    
    all_good = True
    
    print("\n1. Checking port availability...")
    if not check_port():
        all_good = False
    
    print("\n2. Checking required dependencies...")
    if not check_dependencies():
        all_good = False
    
    print("\n3. Checking model files...")
    if not check_model_files():
        all_good = False
        print("\nIMPORTANT: Missing model files! Run check_models.py to create a test model.")
    
    # Add explanation of architecture
    explain_architecture()
    
    if all_good:
        print("\nAll checks passed! Running server test...")
        run_simple_test()
        print("\nDiagnostic complete. The server should work correctly.")
        print("To start the server, run: python prediction_api.py")
    else:
        print("\nSome checks failed. Please fix the issues above before starting the server.")
