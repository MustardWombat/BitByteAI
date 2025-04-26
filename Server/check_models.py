import os
import sys

def check_model_files():
    """Check if model files and directories exist, create if needed"""
    
    # Check for output_models directory
    if not os.path.exists("output_models"):
        print("Creating output_models directory...")
        os.makedirs("output_models")
        print("You'll need to add model files to this directory")
        
    # Check for model files
    coreml_path = "output_models/NotificationTimePredictor.mlmodel"
    sklearn_path = "output_models/NotificationTimePredictor.pkl"
    
    if not os.path.exists(coreml_path) and not os.path.exists(sklearn_path):
        print("\nWARNING: No model files found!")
        print(f"Missing: {coreml_path}")
        print(f"Missing: {sklearn_path}")
        print("\nYou need at least one of these model files for the server to work.")
        print("Would you like to create a dummy model for testing? (y/n)")
        
        choice = input().strip().lower()
        if choice == 'y':
            try:
                import numpy as np
                import pickle
                from sklearn.ensemble import RandomForestRegressor
                
                print("Creating a simple dummy model...")
                model = RandomForestRegressor(n_estimators=10)
                X = np.random.rand(100, 5)
                y = np.random.rand(100)
                model.fit(X, y)
                
                with open(sklearn_path, 'wb') as f:
                    pickle.dump(model, f)
                print(f"Created dummy model at: {sklearn_path}")
                return True
            except ImportError:
                print("Could not create dummy model: scikit-learn not installed")
                return False
    else:
        found = []
        if os.path.exists(coreml_path):
            found.append("CoreML model")
        if os.path.exists(sklearn_path):
            found.append("scikit-learn model")
            
        print(f"Found model files: {', '.join(found)}")
        return True
        
if __name__ == "__main__":
    print("Checking for model files...")
    if check_model_files():
        print("Model check complete. You should be able to start the server now.")
    else:
        print("Please add model files to the output_models directory.")
