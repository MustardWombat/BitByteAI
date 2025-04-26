import os
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

DATA_DIR = "collected_data"
os.makedirs(DATA_DIR, exist_ok=True)

def generate_synthetic_data(num_samples=1000, days_back=30):
    """Generate synthetic data for testing the model training pipeline"""
    
    # Start date for the synthetic data
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days_back)
    
    # Generate random timestamps
    timestamps = [start_date + (end_date - start_date) * random.random() 
                  for _ in range(num_samples)]
    timestamps.sort()  # Sort chronologically
    
    # Create dataframe
    df = pd.DataFrame({
        'timestamp': timestamps,
        'userId': [f"user_{random.randint(1, 10)}" for _ in range(num_samples)],
        
        # Time features
        'dayOfWeek': [ts.weekday() for ts in timestamps],
        'hourOfDay': [ts.hour for ts in timestamps],
        'minuteOfHour': [ts.minute for ts in timestamps],
        
        # Device features - examples
        'device_activity': np.random.uniform(0, 1, num_samples),
        'device_batteryLevel': np.random.uniform(0.1, 1, num_samples),
        'device_screenActive': np.random.choice([0, 1], size=num_samples),
        'device_appInForeground': np.random.choice([0, 1], size=num_samples),
        'device_audioPlaying': np.random.choice([0, 1], size=num_samples),
        
        # Target variable - response time in seconds
        # Model this as influenced by time of day and device state
        'responseTime': np.zeros(num_samples)
    })
    
    # Make the response time depend on features in a non-linear way
    for i in range(num_samples):
        hour = df.loc[i, 'hourOfDay']
        day = df.loc[i, 'dayOfWeek']
        activity = df.loc[i, 'device_activity']
        battery = df.loc[i, 'device_batteryLevel']
        screen = df.loc[i, 'device_screenActive']
        
        # People respond faster during working hours and weekdays
        time_factor = 1.0
        if 9 <= hour <= 17:  # Working hours
            time_factor = 0.7
        if hour < 7 or hour > 22:  # Night time
            time_factor = 2.0
        if day >= 5:  # Weekend
            time_factor *= 1.3
            
        # Device state affects response time
        device_factor = 1.0
        if screen == 1:  # Screen is active
            device_factor = 0.6
        if activity > 0.7:  # High activity
            device_factor *= 1.5
        if battery < 0.3:  # Low battery
            device_factor *= 1.2
            
        # Base response time is between 10 and 300 seconds, modified by factors
        base_time = random.uniform(10, 300)
        df.loc[i, 'responseTime'] = base_time * time_factor * device_factor
    
    # Format timestamp as string
    df['timestamp'] = df['timestamp'].astype(str)
    
    return df

if __name__ == "__main__":
    print("Generating synthetic training data...")
    
    # Generate data
    synthetic_data = generate_synthetic_data(num_samples=2000)
    
    # Save to CSV
    output_path = os.path.join(DATA_DIR, f"processed_synthetic_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")
    synthetic_data.to_csv(output_path, index=False)
    
    print(f"Generated {len(synthetic_data)} samples and saved to {output_path}")
    print("\nSample data:")
    print(synthetic_data.head())
    
    print("\nColumn statistics:")
    print(synthetic_data.describe())
