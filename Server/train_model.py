import os
import pandas as pd
import numpy as np
import glob
import pickle
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error
import coremltools as ct

DATA_DIR = "collected_data"
OUTPUT_DIR = "output_models"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def load_and_prepare_data():
    """Load data from all collected CSVs and prepare for model training"""
    # Find all processed CSV files
    csv_files = glob.glob(os.path.join(DATA_DIR, "processed_*.csv"))
    
    if not csv_files:
        print("No data files found for training")
        return None
    
    # Combine all data files
    dfs = []
    for file in csv_files:
        try:
            df = pd.read_csv(file)
            dfs.append(df)
        except Exception as e:
            print(f"Error loading file {file}: {str(e)}")
    
    if not dfs:
        return None
        
    # Combine all dataframes
    combined_df = pd.concat(dfs, ignore_index=True)
    
    # Clean and prepare data
    # Note: Adjust these preprocessing steps based on your actual data structure
    # This is a simplified example
    
    # Drop any rows with missing values
    combined_df = combined_df.dropna()
    
    print(f"Loaded {len(combined_df)} data points for training")
    return combined_df

def train_notification_time_model(data):
    """Train a model to predict optimal notification times"""
    # Feature engineering
    # Note: You should adapt these features based on your actual data
    features = [col for col in data.columns if col.startswith('device_') or
                col in ['dayOfWeek', 'hourOfDay', 'minuteOfHour']]
    
    # Add time-based features if they don't exist
    if 'timestamp' in data.columns and 'dayOfWeek' not in data.columns:
        data['timestamp'] = pd.to_datetime(data['timestamp'])
        data['dayOfWeek'] = data['timestamp'].dt.dayofweek
        data['hourOfDay'] = data['timestamp'].dt.hour
        data['minuteOfHour'] = data['timestamp'].dt.minute
    
    # Target variable - assuming 'responseTime' or similar exists
    # Adjust based on your actual target variable
    target = 'responseTime'
    if target not in data.columns:
        print(f"Target variable '{target}' not found in data")
        # For demo, use a random column or create synthetic data
        data[target] = np.random.randint(0, 100, size=len(data))
    
    # Ensure features exist in the data
    features = [f for f in features if f in data.columns]
    
    if not features:
        print("No valid features found in data")
        return None
    
    # Split data
    X = data[features]
    y = data[target]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train a simple model
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate
    predictions = model.predict(X_test)
    mae = mean_absolute_error(y_test, predictions)
    print(f"Model MAE: {mae}")
    
    # Export as CoreML model
    model_path = os.path.join(OUTPUT_DIR, "NotificationTimePredictor.mlmodel")
    
    # Convert to CoreML
    try:
        coreml_model = ct.converters.sklearn.convert(model, 
                                                  input_features=[(f, ct.TensorType(shape=(1,))) for f in features],
                                                  output_feature_names=['notificationTime'])
        # Save the model
        coreml_model.save(model_path)
        print(f"Model saved to {model_path}")
    except Exception as e:
        print(f"Error converting to CoreML: {str(e)}")
        model_path = None
    
    # Also save the sklearn model directly
    sklearn_model_path = os.path.join(OUTPUT_DIR, "NotificationTimePredictor.pkl")
    with open(sklearn_model_path, 'wb') as f:
        pickle.dump(model, f)
    print(f"Scikit-learn model saved to {sklearn_model_path}")
    
    return model_path

if __name__ == "__main__":
    # Test the training pipeline
    data = load_and_prepare_data()
    if data is not None:
        train_notification_time_model(data)
