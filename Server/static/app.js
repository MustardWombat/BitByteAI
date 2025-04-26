// JavaScript for the Notification Time Predictor web interface

document.addEventListener('DOMContentLoaded', function() {
    // Set up event listeners for range inputs
    const activitySlider = document.getElementById('device_activity');
    const activityValue = document.getElementById('device_activity_value');
    const batterySlider = document.getElementById('device_batteryLevel');
    const batteryValue = document.getElementById('device_batteryLevel_value');
    
    activitySlider.addEventListener('input', () => {
        activityValue.textContent = activitySlider.value;
    });
    
    batterySlider.addEventListener('input', () => {
        batteryValue.textContent = batterySlider.value;
    });
    
    // Form submission
    const predictionForm = document.getElementById('prediction-form');
    predictionForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        
        // Get values from form
        const data = {
            dayOfWeek: parseInt(document.getElementById('dayOfWeek').value),
            hourOfDay: parseInt(document.getElementById('hourOfDay').value),
            minuteOfHour: parseInt(document.getElementById('minuteOfHour').value),
            device_activity: parseFloat(document.getElementById('device_activity').value),
            device_batteryLevel: parseFloat(document.getElementById('device_batteryLevel').value)
        };
        
        // Show loading state
        const submitBtn = predictionForm.querySelector('button[type="submit"]');
        const originalBtnText = submitBtn.textContent;
        submitBtn.textContent = 'Predicting...';
        submitBtn.disabled = true;
        
        try {
            // Make API request
            const response = await fetch('/predict', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });
            
            // Parse response
            const result = await response.json();
            
            if (response.ok) {
                // Update UI with prediction
                document.getElementById('prediction-value').textContent = 
                    result.prediction.toFixed(2);
                document.getElementById('result').classList.remove('hidden');
            } else {
                // Handle API error
                alert(`Error: ${result.error || 'Unknown error'}`);
            }
        } catch (error) {
            console.error('Error making prediction:', error);
            alert('Failed to get prediction. Please try again.');
        } finally {
            // Reset button
            submitBtn.textContent = originalBtnText;
            submitBtn.disabled = false;
        }
    });
    
    // Check API health status on page load
    checkApiHealth();
});

async function checkApiHealth() {
    const statusIndicator = document.getElementById('status-indicator');
    const statusDot = statusIndicator.querySelector('.dot');
    const statusText = document.getElementById('status-text');
    
    try {
        const response = await fetch('/health');
        const data = await response.json();
        
        if (response.ok && data.status === 'ok') {
            statusDot.classList.add('online');
            statusText.textContent = 'API Online';
            
            if (data.model_available) {
                statusText.textContent += ' - Model Ready';
            } else {
                statusText.textContent += ' - Model Not Available';
                statusDot.classList.add('offline');
            }
        } else {
            statusDot.classList.add('offline');
            statusText.textContent = 'API Issues Detected';
        }
    } catch (error) {
        statusDot.classList.add('offline');
        statusText.textContent = 'API Offline';
    }
}
